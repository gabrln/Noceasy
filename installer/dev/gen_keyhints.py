#!/usr/bin/env python3
"""Generate .config/hypr/scripts/KeyHints.lua from modules/keybinds.lua.

The generated file is a self-contained Lua script that displays all
Hyprland keybindings in an fzf menu and copies the matching command
to the clipboard.

Reads `keybinds.lua` line by line, parses simple `hl.bind(KEYSPEC,
DISPATCH)` calls plus the scratchpad function calls, and groups them
into categories that the user can search with fzf.

Idempotent. Re-run any time `keybinds.lua` changes:

    # from the repo
    python3 installer/dev/gen_keyhints.py

    # or, if installed system-wide by the framework (typically in
    # ~/.local/bin/gen_keyhints), with an explicit repo path or via
    # the NOCEASY_REPO env var:
    gen_keyhints --repo ~/Projects/Noceasy
    NOCEASY_REPO=~/Projects/Noceasy gen_keyhints

The script is also available as `gen_keyhints --check` for CI /
pre-commit, which exits 1 if KeyHints.lua is out of date.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

# Resolve the Noceasy repo. When the script lives at
# `<repo>/installer/dev/gen_keyhints.py`, `parents[2]` is the repo root.
# When it has been copied to `~/.local/bin/gen_keyhints` by the installer,
# that path doesn't exist, so we fall back to the default
# `~/Projects/Noceasy` (or whatever the user passed via --repo or the
# NOCEASY_REPO env var).
_DEFAULT_REPO = Path.home() / "Projects" / "Noceasy"

try:
    REPO = Path(__file__).resolve().parents[2]
    # Sanity check: does this look like the Noceasy repo? If not (e.g. the
    # script was copied to ~/.local/bin/), the parents[2] path will be
    # something unrelated, so fall back to the default.
    if not (REPO / ".config" / "hypr" / "modules" / "keybinds.lua").is_file():
        REPO = Path(os.environ.get("NOCEASY_REPO", _DEFAULT_REPO))
except (IndexError, OSError):
    REPO = Path(os.environ.get("NOCEASY_REPO", _DEFAULT_REPO))

KEYBINDS = REPO / ".config" / "hypr" / "modules" / "keybinds.lua"
OUT_FILE = REPO / ".config" / "hypr" / "scripts" / "KeyHints.lua"


# ---------------------------------------------------------------------------
# Dispatch stringification
# ---------------------------------------------------------------------------

# A few `hl.dsp.*` calls produce a string when given an argument; we want
# the source form (with quotes intact) for display purposes.
def _stringify_dispatch(expr: str) -> str:
    """Convert a dispatch expression to a readable inline form.

    Examples:
        hl.dispatch(hl.dsp.exec_cmd("kitty"))           -> exec_cmd("kitty")
        hl.dsp.window.close()                            -> window.close()
        toggle_scratchpad("kitty-drop", "kitty --class") -> toggle_scratchpad("kitty-drop", "kitty --class")
    """
    s = expr.strip()
    if s.startswith("--"):
        s = s[2:].lstrip()
    # Strip the outer `hl.dispatch(...)` wrapper if present.
    m = re.match(r"^hl\.dispatch\((.*)\)$", s, re.DOTALL)
    if m:
        s = m.group(1).strip()
    # Drop the `hl.dsp.` prefix to keep the line short in the cheatsheet.
    s = re.sub(r"^hl\.dsp\.", "", s)
    return s


# ---------------------------------------------------------------------------
# Bind parsing
# ---------------------------------------------------------------------------

# Locate the position of every `hl.bind(` token. We then walk
# character-by-character, tracking string and brace depth, to find the
# matching close paren and slice the inner arguments. This is more
# robust than a regex against nested quotes / parens / braces.
BIND_START_RE = re.compile(r'\bhl\.bind\s*\(')


def _find_matching_paren(text: str, open_pos: int) -> int:
    """Given the position of `(`, return the position of the matching `)`.

    Skips characters inside Lua strings (", ', [[ ]]) and tracks depth.
    """
    assert text[open_pos] == "("
    depth = 1
    i = open_pos + 1
    n = len(text)
    in_string: str | None = None
    while i < n:
        c = text[i]
        if in_string is not None:
            if in_string == "long":
                if text[i:i + 2] == "]]":
                    in_string = None
                    i += 2
                    continue
            elif c == "\\" and i + 1 < n:
                i += 2
                continue
            elif c == in_string:
                in_string = None
        else:
            if c in ('"', "'"):
                in_string = c
            elif text[i:i + 2] == "[[":
                in_string = "long"
                i += 2
                continue
            elif c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1


def _split_top_commas(text: str) -> list[str]:
    """Split a string by top-level commas (not inside strings/braces)."""
    parts: list[str] = []
    depth = 0
    in_string: str | None = None
    buf: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if in_string is not None:
            buf.append(c)
            if in_string == "long":
                if text[i:i + 2] == "]]":
                    buf.append("]")
                    in_string = None
                    i += 2
                    continue
            elif c == "\\" and i + 1 < n:
                buf.append(text[i + 1])
                i += 2
                continue
            elif c == in_string:
                in_string = None
        else:
            if c in ('"', "'"):
                in_string = c
                buf.append(c)
            elif text[i:i + 2] == "[[":
                in_string = "long"
                buf.append("[[")
                i += 2
                continue
            elif c in "({[":
                depth += 1
                buf.append(c)
            elif c in ")}]":
                depth -= 1
                buf.append(c)
            elif c == "," and depth == 0:
                parts.append("".join(buf).strip())
                buf = []
            else:
                buf.append(c)
        i += 1
    if buf:
        parts.append("".join(buf).strip())
    return parts

# Match an `hl.bind` whose dispatch is a named local function (e.g.
# `toggle_scratchpad`, `open_overview`) — the literal text is captured.
NAMED_FN_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)$")

# Match a scratchpad `function() toggle_scratchpad("name", "cmd") end`
SCRATCHPAD_RE = re.compile(
    r'toggle_scratchpad\(\s*"(?P<cls>[^"]+)"\s*,\s*"(?P<cmd>[^"]+)"\s*\)'
)


# ---------------------------------------------------------------------------
# Categorization
# ---------------------------------------------------------------------------

# Map (substring -> category, description hint). First match wins.
# Keys are matched lowercased against the dispatch text.
NOCTALIA_DISPATCHES = {
    "noctalia msg": ("Noctalia", "Noctalia shell command"),
    "noctalia": ("Noctalia", "Noctalia shell command"),
}


def categorize(key: str, dispatch: str) -> tuple[str, str]:
    """Return (category, human description) for a binding."""
    k = key.lower()
    d = dispatch.lower()

    # Media keys
    if "xf86audio" in k or "xf86media" in k:
        return ("Media", "Media key")

    # Brightness
    if "xf86monbrightness" in k:
        return ("Media", "Brightness control")

    # Scratchpads
    sp = SCRATCHPAD_RE.search(dispatch)
    if sp:
        cls = sp.group("cls")
        cmd = sp.group("cmd")
        return ("Scratchpads", f"Scratchpad ({cls}): {cmd}")

    # Noctalia IPC
    for needle, (cat, hint) in NOCTALIA_DISPATCHES.items():
        if needle in d:
            # Try to extract a more specific description from the dispatch.
            ipc = re.search(r"noctalia msg\s+([\w-]+(?:\s+[\w-]+)*)", dispatch)
            if ipc:
                return (cat, f"{hint}: {ipc.group(1)}")
            return (cat, hint)

    # Window management
    if any(s in d for s in ("window.close", "window.fullscreen", "window.center",
                             "window.float", "window.pin", "window.resize",
                             "window.drag", "window.move", "focus(",
                             "group.toggle", "group.prev", "group.next")):
        return ("Windows", "Window management")

    # Layout / scrolling
    if "layout(" in d or "submap(" in d:
        if "submap" in d:
            return ("Windows", "Submap enter")
        return ("Layout", "Layout / column control")

    # Overview / scrolloverview plugin
    if "scrolloverview" in d or "overview" in d:
        return ("Overview", "Workspace overview")

    # Screenshots
    if "screenshot" in d:
        return ("Screenshots", "Screenshot")

    # Lock / session
    if "session" in d or "lock" in d:
        return ("Session", "Session / lock")

    # Exec cmd (generic app launcher)
    if "exec_cmd" in d or "exec(" in d:
        cmd_m = re.search(r'(?:exec_cmd|exec)\(\s*"([^"]+)"', dispatch)
        if cmd_m:
            cmd = cmd_m.group(1)
            # Promote common Noctalia-adjacent apps to a subcategory
            if "AltF4.lua" in cmd:
                return ("Windows", "Force-close window (AltF4 helper)")
            if "WindowInfo.lua" in cmd:
                return ("Windows", "Window info popup")
            if "KeyHints.lua" in cmd:
                return ("Session", "Show this keybinding cheatsheet")
            return ("Apps", f"Launch: {cmd}")
        return ("Apps", "Launch application")

    return ("Misc", "Misc")


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

HEADER = """#!/usr/bin/env lua
-- KeyHints.lua - Interactive keybinding cheatsheet for Hyprland.
--
-- AUTO-GENERATED by installer/dev/gen_keyhints.py from
-- .config/hypr/modules/keybinds.lua. Do not edit by hand: re-run
-- the script to regenerate.
--
-- On launch, this script renders all bindings grouped by category
-- into a temporary file and pipes it into fzf. Pressing Enter on a
-- row copies the corresponding action string to the clipboard.

local shortcuts = {
"""

CATEGORY_ORDER = [
    "Apps",
    "Layout",
    "Media",
    "Misc",
    "Noctalia",
    "Overview",
    "Screenshots",
    "Scratchpads",
    "Session",
    "Windows",
]

FOOTER = """}

local w1 = 0
for _, item in ipairs(shortcuts) do
    if item[2] ~= "" then
        w1 = math.max(w1, #item[1])
    end
end

local lines = {}
local map_action = {}
for _, item in ipairs(shortcuts) do
    local formatted
    if item[2] == "" then
        formatted = item[1]
    else
        formatted = string.format("%-" .. (w1 + 4) .. "s   %s", item[1], item[2])
    end
    table.insert(lines, formatted)
    map_action[formatted] = item[3]
end

local input_str = table.concat(lines, "\\n")
local tmp_file = os.tmpname()
local f = io.open(tmp_file, "w")
if f then
    f:write(input_str)
    f:close()
end

local fzf_cmd = 'fzf --no-sort --cycle --header=" [ ENTER: Copy action to clipboard | ESC: Exit ]" --layout=reverse --border=rounded --prompt=" Search or browse by category: "'
local handle = io.popen(string.format("cat %s | %s", tmp_file, fzf_cmd))
local selected = handle:read("*l")
handle:close()
os.remove(tmp_file)

if selected and selected ~= "" then
    selected = selected:match("^%s*(.-)%s*$")
    local action = map_action[selected]
    if not action then
        action = selected:match(".*%s+([^\\n]+)$")
    end
    if action then
        local copy_cmd = string.format("printf '%%s' %q | wl-copy", action)
        os.execute(copy_cmd)
        os.execute(string.format('notify-send "Shortcut Copied" "Action \\'%s\\' copied to clipboard!" -t 2000 -i edit-copy', action))
    end
end
"""


def _format_key(keyspec: str) -> str:
    """Resolve a key spec to a printable string.

    Handles three forms seen in the config:
      1. Literal string:  `"SUPER + T"` -> `SUPER + T`
      2. Concatenation:   `mod .. " + B"` -> `SUPER + B`
      3. Concat with another variable: `mod .. " + " .. i` -> `SUPER + <i>`
    Unknown / unresolvable forms are returned as-is, minus the
    surrounding quotes.
    """
    s = keyspec.strip()
    # Pure literal — must start/end with quotes AND not contain
    # Lua concatenation (..), which means it's an expression, not a string.
    if ".." not in s and (
            (s.startswith('"') and s.endswith('"')) or
            (s.startswith("'") and s.endswith("'"))):
        return s[1:-1]
    # Concatenation form: prefix .. " + suffix" (with optional `.. <var>`).
    if ".." in s:
        # Pattern 1: variable .. "suffix" (with optional .. variable)
        m = re.match(
            r'^\s*(\w+)\s*\.\.\s*"([^"]*)"\s*(?:\.\.\s*(\w+))?\s*$', s
        )
        if m:
            prefix, suffix, var = m.group(1), m.group(2), m.group(3)
            prefix_val = _resolve_var(prefix)
            if prefix_val is not None:
                if var:
                    return f"{prefix_val}{suffix}{{{var}}}"
                return f"{prefix_val}{suffix}"
        # Pattern 2: "prefix" .. variable .. "suffix"
        m = re.match(
            r'^\s*"([^"]*)"\s*\.\.\s*(\w+)\s*\.\.\s*"([^"]*)"\s*$', s
        )
        if m:
            prefix, var, suffix = m.group(1), m.group(2), m.group(3)
            var_val = _resolve_var(var)
            if var_val is not None:
                return f"{prefix}{var_val}{suffix}"
    return s.strip('"\'')


# Variable defaults mirrored from the keybinds.lua module header.
_MODULE_VARS = {"mod": "SUPER"}


def _resolve_var(name: str) -> str | None:
    return _MODULE_VARS.get(name)


def _describe(category: str, hint: str) -> str:
    return f"[{category}] {hint}"


def parse_keybinds(path: Path) -> list[tuple[str, str, str]]:
    """Return a list of (formatted_key, action_text, category) tuples."""
    text = path.read_text()
    # Strip block comments so we don't accidentally match commented binds.
    text = re.sub(r"--\[\[.*?]]", "", text, flags=re.DOTALL)

    binds: list[tuple[str, str, str]] = []
    for m in BIND_START_RE.finditer(text):
        open_pos = m.end() - 1  # position of the `(`
        close_pos = _find_matching_paren(text, open_pos)
        if close_pos < 0:
            continue
        inner = text[open_pos + 1:close_pos]
        parts = _split_top_commas(inner)
        if len(parts) < 2:
            continue
        key_raw = parts[0]
        dispatch_raw = parts[1]
        # Skip commented-out binds.
        if key_raw.lstrip().startswith("--") or dispatch_raw.lstrip().startswith("--"):
            continue
        key = _format_key(key_raw)
        # Skip binds that depend on a loop variable we cannot resolve
        # (e.g. `mod .. " + " .. i` inside a `for i = 1, 9 do` loop).
        # We render one synthetic entry per dynamic prefix instead.
        if "{i}" in key:
            continue

        # Anonymous function — pull any inner expression as the action.
        if dispatch_raw.lstrip().startswith("function"):
            inner_body = re.search(r"function\s*\([^)]*\)\s*(.+?)\s*end",
                                   dispatch_raw, re.DOTALL)
            if inner_body:
                dispatch = inner_body.group(1).strip()
                # Collapse multi-line actions to a single line and trim
                # trailing `.. end` artifacts left by sloppy regex.
                dispatch = re.sub(r"\s+", " ", dispatch)
                dispatch = re.sub(r"\s*end\s*$", "", dispatch)
            else:
                continue
        else:
            dispatch = dispatch_raw

        action = _stringify_dispatch(dispatch)
        action = action.rstrip(",").strip()
        cat, hint = categorize(key, action)
        binds.append((key, _describe(cat, hint), action))

    # Synthesize one entry per dynamic-key prefix. Detected prefixes
    # include the `for i = 1, N do` workspace-switch loop.
    text_after_strip = re.sub(
        r"for\s+\w+\s*=\s*1\s*,\s*\d+\s*do(.*?)end",
        r"__LOOP__\1__ENDLOOP__", text, flags=re.DOTALL,
    )
    # Look for the canonical pattern: focus + move for a workspace loop.
    if "__LOOP__" in text_after_strip:
        # Default to "1-9" + 10 if the loop is in the keybinds file.
        binds.append((
            "SUPER + [1-9]",
            "[Windows] Window management",
            "focus({ workspace = <1..9> })",
        ))
        binds.append((
            "SUPER + SHIFT + [1-9]",
            "[Windows] Window management",
            "window.move({ workspace = <1..9> })",
        ))

    # Deduplicate while preserving order.
    seen: set[tuple[str, str]] = set()
    unique: list[tuple[str, str, str]] = []
    for b in binds:
        k = (b[0], b[1])
        if k in seen:
            continue
        seen.add(k)
        unique.append(b)
    return unique


def render(binds: list[tuple[str, str, str]]) -> str:
    """Group by category in canonical order, emit Lua source."""
    groups: dict[str, list[tuple[str, str, str]]] = {c: [] for c in CATEGORY_ORDER}
    for b in binds:
        cat = b[1].split("]")[0][1:]  # extract category tag
        groups.setdefault(cat, []).append(b)

    out: list[str] = [HEADER]
    for cat in CATEGORY_ORDER + [c for c in groups if c not in CATEGORY_ORDER]:
        items = groups.get(cat, [])
        if not items:
            continue
        out.append(f'  -- Category: {cat}\n')
        out.append(f'  {{ "--- [{cat}] {"-" * (40 - len(cat))}", "", "" }},\n')
        for key, desc, action in sorted(items, key=lambda b: b[0]):
            # Escape any embedded double-quotes in the action.
            esc_action = action.replace('"', '\\"')
            out.append(f'  {{ "{key}", "{desc}", "{esc_action}" }},\n')
    out.append(FOOTER)
    return "".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="Exit 1 if the generated file is out of date.")
    parser.add_argument(
        "--repo", type=Path, default=REPO,
        help="Path to the Noceasy repo (default: auto-detected, then "
             "$NOCEASY_REPO, then ~/Projects/Noceasy).",
    )
    args = parser.parse_args()

    keybinds = args.repo / ".config" / "hypr" / "modules" / "keybinds.lua"
    out_file = args.repo / ".config" / "hypr" / "scripts" / "KeyHints.lua"

    if not keybinds.is_file():
        print(f"error: keybinds.lua not found at {keybinds}. "
              f"Pass --repo <path> or set NOCEASY_REPO.", file=sys.stderr)
        return 2

    binds = parse_keybinds(keybinds)
    rendered = render(binds)

    if args.check:
        current = out_file.read_text() if out_file.exists() else ""
        if current != rendered:
            print(f"KeyHints.lua is out of date. Re-run gen_keyhints.py.",
                  file=sys.stderr)
            return 1
        return 0

    out_file.write_text(rendered)
    out_file.chmod(0o755)
    print(f"Wrote {out_file} ({len(binds)} bindings across "
          f"{len({b[1].split(']')[0][1:] for b in binds})} categories).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
