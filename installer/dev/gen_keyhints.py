#!/usr/bin/env python3
"""Generate .config/hypr/scripts/KeyHints_data.lua from modules/keybinds.lua.

The generated file is a Lua data module (returning a table of shortcut
entries) consumed by KeyHints_runner.lua, which renders an fzf menu
and copies the selected action to the clipboard.

Categories are derived from ``═══`` section headers in ``keybinds.lua``.
The ``-- @group`` annotation overrides the display category; ``-- @desc``
provides a custom human-readable description.

Idempotent. Re-run any time ``keybinds.lua`` changes:

    # from the repo
    python3 installer/dev/gen_keyhints.py

    # or, if installed system-wide by the framework (typically in
    # ~/.local/bin/gen_keyhints), with an explicit repo path or via
    # the NOCEASY_REPO env var:
    gen_keyhints --repo ~/Projects/Noceasy
    NOCEASY_REPO=~/Projects/Noceasy gen_keyhints

The script is also available as ``gen_keyhints --check`` for CI /
pre-commit, which exits 1 if KeyHints_data.lua is out of date.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Repo resolution
# ---------------------------------------------------------------------------

_DEFAULT_REPO = Path.home() / "Projects" / "Noceasy"

try:
    REPO = Path(__file__).resolve().parents[2]
    if not (REPO / ".config" / "hypr" / "modules" / "keybinds.lua").is_file():
        REPO = Path(os.environ.get("NOCEASY_REPO", _DEFAULT_REPO))
except (IndexError, OSError):
    REPO = Path(os.environ.get("NOCEASY_REPO", _DEFAULT_REPO))

KEYBINDS = REPO / ".config" / "hypr" / "modules" / "keybinds.lua"
OUT_FILE = REPO / ".config" / "hypr" / "scripts" / "KeyHints_data.lua"

# ---------------------------------------------------------------------------
# Regex patterns
# ---------------------------------------------------------------------------

# Section headers: -- ═══ CategoryName ══════════════════════════════════════
SECTION_HEADER_RE = re.compile(r"--\s*═+\s*(.+?)\s*═+")

# Annotation: -- @group DisplayGroup
GROUP_ANNOTATION_RE = re.compile(r"--\s*@group\s+(.+)")

# Annotation: -- @desc Description text
DESC_ANNOTATION_RE = re.compile(r"--\s*@desc\s+(.+)")

# Locate every hl.bind( token.
BIND_START_RE = re.compile(r'\bhl\.bind\s*\(')

# Variable defaults mirrored from the keybinds.lua module header.
_MODULE_VARS = {"mod": "SUPER"}

# ---------------------------------------------------------------------------
# Dispatch stringification
# ---------------------------------------------------------------------------

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
    m = re.match(r"^hl\.dispatch\((.*)\)$", s, re.DOTALL)
    if m:
        s = m.group(1).strip()
    s = re.sub(r"^hl\.dsp\.", "", s)
    return s

# ---------------------------------------------------------------------------
# Paren / comma helpers
# ---------------------------------------------------------------------------

def _find_matching_paren(text: str, open_pos: int) -> int:
    """Given the position of ``(``, return the position of the matching ``)``.

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

# ---------------------------------------------------------------------------
# Key formatting
# ---------------------------------------------------------------------------

def _resolve_var(name: str) -> str | None:
    return _MODULE_VARS.get(name)


def _format_key(keyspec: str) -> str:
    """Resolve a key spec to a printable string.

    Handles three forms seen in the config:
      1. Literal string:  ``"SUPER + T"`` -> ``SUPER + T``
      2. Concatenation:   ``mod .. " + B"`` -> ``SUPER + B``
      3. Concat with loop var: ``mod .. " + " .. i`` -> ``SUPER + {i}``
    """
    s = keyspec.strip()
    if ".." not in s and (
            (s.startswith('"') and s.endswith('"')) or
            (s.startswith("'") and s.endswith("'"))):
        return s[1:-1]
    if ".." in s:
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
        m = re.match(
            r'^\s*"([^"]*)"\s*\.\.\s*(\w+)\s*\.\.\s*"([^"]*)"\s*$', s
        )
        if m:
            prefix, var, suffix = m.group(1), m.group(2), m.group(3)
            var_val = _resolve_var(var)
            if var_val is not None:
                return f"{prefix}{var_val}{suffix}"
    return s.strip('"\'')

# ---------------------------------------------------------------------------
# Section header parsing
# ---------------------------------------------------------------------------

def _parse_section_headers(text: str) -> list[tuple[int, str, str | None]]:
    """Return ``(position, raw_category, display_group)`` for each header.

    ``display_group`` is ``None`` unless the next line contains
    ``-- @group <name>``, in which case it overrides the category for
    display purposes.
    """
    lines = text.split("\n")
    headers: list[tuple[int, str, str | None]] = []
    for idx, line in enumerate(lines):
        m = SECTION_HEADER_RE.search(line)
        if m:
            raw_cat = m.group(1).strip()
            # Check next line for @group annotation
            display_group = None
            if idx + 1 < len(lines):
                gm = GROUP_ANNOTATION_RE.search(lines[idx + 1])
                if gm:
                    display_group = gm.group(1).strip()
            # Position is the character offset (for matching against bind positions)
            pos = sum(len(l) + 1 for l in lines[:idx])
            headers.append((pos, raw_cat, display_group))
    return headers


def _find_header_for_position(
    headers: list[tuple[int, str, str | None]],
    bind_pos: int,
) -> str:
    """Return the display category for the header preceding *bind_pos*."""
    result = "Misc"
    for pos, raw_cat, group in headers:
        if pos < bind_pos:
            result = group if group else raw_cat
        else:
            break
    return result

# ---------------------------------------------------------------------------
# Description generation
# ---------------------------------------------------------------------------

def _generate_description(dispatch: str) -> str:
    """Generate a human-readable description from a dispatch string."""
    s = dispatch.strip()
    s = re.sub(r"^hl\.dsp\.", "", s)

    # exec_cmd("...") → extract the command name
    m = re.match(r'exec_cmd\(\s*"([^"]+)"\s*\)', s)
    if m:
        cmd = m.group(1)
        basename = cmd.rsplit("/", 1)[-1]
        return f"Launch {basename}"

    # window.close() → Close
    if s == "window.close()":
        return "Close"
    if s == "window.fullscreen()":
        return "Fullscreen"
    if s == "window.center()":
        return "Center"
    if s == "window.drag()":
        return "Drag window"
    if s == "window.resize()":
        return "Resize window"
    m = re.match(r"window\.\w+\(", s)
    if m:
        method = s.split("(")[0].split(".")[-1]
        return f"Window {method}"

    # focus({ direction = "left" }) → Focus left
    m = re.match(r'focus\(\s*\{\s*direction\s*=\s*"(\w+)"', s)
    if m:
        return f"Focus {m.group(1)}"
    if "focus(" in s:
        return "Focus workspace"

    if s == "group.toggle()":
        return "Toggle group"
    if s == "group.prev()":
        return "Previous group"
    if s == "group.next()":
        return "Next group"

    # layout("...") → Layout / command
    m = re.match(r'layout\(\s*"([^"]+)"\s*\)', s)
    if m:
        return f"Layout {m.group(1)}"

    # toggle_scratchpad("name", "cmd") → Toggle name
    m = re.match(r'toggle_scratchpad\(\s*"([^"]+)"', s)
    if m:
        return f"Toggle {m.group(1)}"

    # Default: extract method name
    m = re.match(r"(\w+(?:\.\w+)*)\s*\(", s)
    if m:
        parts = m.group(1).split(".")
        return " ".join(p.capitalize() for p in parts)

    return s

# ---------------------------------------------------------------------------
# Bind parsing
# ---------------------------------------------------------------------------

def parse_keybinds(path: Path) -> list[tuple[str, str, str, str]]:
    """Return ``(formatted_key, description, action, group)`` tuples."""
    text = path.read_text()
    text = re.sub(r"--\[\[.*?]]", "", text, flags=re.DOTALL)

    headers = _parse_section_headers(text)

    binds: list[tuple[str, str, str, str]] = []
    lines = text.split("\n")

    for m in BIND_START_RE.finditer(text):
        open_pos = m.end() - 1
        close_pos = _find_matching_paren(text, open_pos)
        if close_pos < 0:
            continue
        inner = text[open_pos + 1:close_pos]
        parts = _split_top_commas(inner)
        if len(parts) < 2:
            continue
        key_raw = parts[0]
        dispatch_raw = parts[1]
        if key_raw.lstrip().startswith("--") or dispatch_raw.lstrip().startswith("--"):
            continue

        key = _format_key(key_raw)

        # Handle loop variable entries: expand to 1-9
        if "{i}" in key:
            # Find which line this bind is on
            bind_line_offset = text[:m.start()].count("\n")
            group = _find_header_for_position(headers, m.start())
            for num in range(1, 10):
                resolved_key = key.replace("{i}", str(num))
                binds.append((
                    resolved_key,
                    f"[{group}] {_generate_description(dispatch_raw)}",
                    _stringify_dispatch(dispatch_raw).rstrip(",").strip(),
                    group,
                ))
            continue

        # Anonymous function — pull inner expression
        if dispatch_raw.lstrip().startswith("function"):
            inner_body = re.search(r"function\s*\([^)]*\)\s*(.+?)\s*end",
                                   dispatch_raw, re.DOTALL)
            if inner_body:
                dispatch = inner_body.group(1).strip()
                dispatch = re.sub(r"\s+", " ", dispatch)
                dispatch = re.sub(r"\s*end\s*$", "", dispatch)
            else:
                continue
        else:
            dispatch = dispatch_raw

        action = _stringify_dispatch(dispatch)
        action = action.rstrip(",").strip()

        # Find the header for this bind
        group = _find_header_for_position(headers, m.start())

        # Check for @desc annotation on the line after the bind
        bind_line = text[:m.start()].count("\n")
        desc = None
        if bind_line + 1 < len(lines):
            dm = DESC_ANNOTATION_RE.search(lines[bind_line + 1])
            if dm:
                desc = dm.group(1).strip()

        if not desc:
            desc = f"[{group}] {_generate_description(action)}"

        binds.append((key, desc, action, group))

    # Deduplicate while preserving order
    seen: set[tuple[str, str]] = set()
    unique: list[tuple[str, str, str, str]] = []
    for b in binds:
        k = (b[0], b[1])
        if k in seen:
            continue
        seen.add(k)
        unique.append(b)
    return unique

# ---------------------------------------------------------------------------
# Rendering (data-only output)
# ---------------------------------------------------------------------------

def render(binds: list[tuple[str, str, str, str]]) -> str:
    """Emit a Lua data table module."""
    out: list[str] = [
        "-- Auto-generated by gen_keyhints.py — do not edit.\n",
        "return {\n",
    ]
    for key, desc, action, _group in binds:
        esc_action = action.replace('"', '\\"')
        out.append(f'  {{ "{key}", "{desc}", "{esc_action}" }},\n')
    out.append("}\n")
    return "".join(out)

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

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
    out_file = args.repo / ".config" / "hypr" / "scripts" / "KeyHints_data.lua"

    if not keybinds.is_file():
        print(f"error: keybinds.lua not found at {keybinds}. "
              f"Pass --repo <path> or set NOCEASY_REPO.", file=sys.stderr)
        return 2

    binds = parse_keybinds(keybinds)
    rendered = render(binds)

    if args.check:
        current = out_file.read_text() if out_file.exists() else ""
        if current != rendered:
            print(f"KeyHints_data.lua is out of date. Re-run gen_keyhints.py.",
                  file=sys.stderr)
            return 1
        return 0

    out_file.write_text(rendered)
    out_file.chmod(0o755)
    cats = {b[3] for b in binds}
    print(f"Wrote {out_file} ({len(binds)} bindings across "
          f"{len(cats)} categories).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
