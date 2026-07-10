#!/usr/bin/env python3
"""Unit tests for gen_keyhints.py — header-based keyhints generator."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

import gen_keyhints as gkh


class TestFormatKey(unittest.TestCase):
    def test_literal_double_quotes(self):
        self.assertEqual(gkh._format_key('"SUPER + T"'), "SUPER + T")

    def test_literal_single_quotes(self):
        self.assertEqual(gkh._format_key("'SUPER + T'"), "SUPER + T")

    def test_concat_mod_var(self):
        self.assertEqual(gkh._format_key('mod .. " + B"'), "SUPER + B")

    def test_concat_mod_var_with_suffix(self):
        self.assertEqual(gkh._format_key('mod .. " + SHIFT + R"'), "SUPER + SHIFT + R")

    def test_concat_loop_var(self):
        result = gkh._format_key('mod .. " + " .. i')
        self.assertEqual(result, "SUPER + {i}")

    def test_literal_xf86(self):
        self.assertEqual(gkh._format_key('"XF86AudioMute"'), "XF86AudioMute")


class TestFindMatchingParen(unittest.TestCase):
    def test_simple(self):
        self.assertEqual(gkh._find_matching_paren("()", 0), 1)

    def test_nested(self):
        self.assertEqual(gkh._find_matching_paren("(()())", 0), 5)

    def test_string_with_parens(self):
        self.assertEqual(gkh._find_matching_paren('("hello (world)")', 0), 16)

    def test_long_string(self):
        self.assertEqual(gkh._find_matching_paren('([[foo(bar)]])', 0), 13)


class TestSplitTopCommas(unittest.TestCase):
    def test_simple(self):
        self.assertEqual(gkh._split_top_commas("a, b, c"), ["a", "b", "c"])

    def test_inside_string(self):
        self.assertEqual(gkh._split_top_commas('"a,b", c'), ['"a,b"', "c"])

    def test_inside_braces(self):
        self.assertEqual(gkh._split_top_commas('{a, b}, c'), ['{a, b}', "c"])

    def test_single_item(self):
        self.assertEqual(gkh._split_top_commas("hello"), ["hello"])


class TestStringifyDispatch(unittest.TestCase):
    def test_exec_cmd(self):
        self.assertEqual(gkh._stringify_dispatch('hl.dsp.exec_cmd("kitty")'), 'exec_cmd("kitty")')

    def test_window_close(self):
        self.assertEqual(gkh._stringify_dispatch("hl.dsp.window.close()"), "window.close()")

    def test_with_hl_dispatch_wrapper(self):
        self.assertEqual(
            gkh._stringify_dispatch('hl.dispatch(hl.dsp.exec_cmd("kitty"))'),
            'exec_cmd("kitty")'
        )


class TestGenerateDescription(unittest.TestCase):
    def test_exec_cmd_kitty(self):
        self.assertEqual(gkh._generate_description('exec_cmd("kitty")'), "Launch kitty")

    def test_exec_cmd_script(self):
        self.assertEqual(
            gkh._generate_description('exec_cmd("~/.config/hypr/scripts/AltF4.lua")'),
            "Launch AltF4.lua"
        )

    def test_window_close(self):
        self.assertEqual(gkh._generate_description("window.close()"), "Close")

    def test_window_fullscreen(self):
        self.assertEqual(gkh._generate_description("window.fullscreen()"), "Fullscreen")

    def test_focus_direction(self):
        self.assertEqual(gkh._generate_description('focus({ direction = "left" })'), "Focus left")

    def test_focus_workspace(self):
        self.assertEqual(gkh._generate_description('focus({ workspace = "e+1" })'), "Focus workspace")

    def test_group_toggle(self):
        self.assertEqual(gkh._generate_description("group.toggle()"), "Toggle group")

    def test_group_prev(self):
        self.assertEqual(gkh._generate_description("group.prev()"), "Previous group")

    def test_layout(self):
        self.assertEqual(gkh._generate_description('layout("fit active")'), "Layout fit active")

    def test_toggle_scratchpad(self):
        self.assertEqual(
            gkh._generate_description('toggle_scratchpad("kitty-drop", "kitty --class kitty-drop")'),
            "Toggle kitty-drop"
        )


class TestSectionHeaders(unittest.TestCase):
    def test_parse_headers(self):
        text = """
-- ═══ Apps ════════════════════════════════════════
-- ═══ Windows ══════════════════════════════════════
-- @group WindowGroup
-- ═══ Layout ═══════════════════════════════════════
"""
        headers = gkh._parse_section_headers(text)
        self.assertEqual(len(headers), 3)
        self.assertEqual(headers[0][1], "Apps")
        self.assertIsNone(headers[0][2])
        self.assertEqual(headers[1][1], "Windows")
        self.assertEqual(headers[1][2], "WindowGroup")
        self.assertEqual(headers[2][1], "Layout")
        self.assertIsNone(headers[2][2])

    def test_find_header_for_position(self):
        headers = [
            (0, "Apps", None),
            (100, "Windows", "WindowGroup"),
            (200, "Layout", None),
        ]
        self.assertEqual(gkh._find_header_for_position(headers, 50), "Apps")
        self.assertEqual(gkh._find_header_for_position(headers, 150), "WindowGroup")
        self.assertEqual(gkh._find_header_for_position(headers, 250), "Layout")

    def test_section_header_re(self):
        m = gkh.SECTION_HEADER_RE.search("-- ═══ Apps ════════════════════════════")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1), "Apps")

    def test_group_annotation_re(self):
        m = gkh.GROUP_ANNOTATION_RE.search("-- @group Windows")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1), "Windows")

    def test_desc_annotation_re(self):
        m = gkh.DESC_ANNOTATION_RE.search("-- @desc Toggle floating")
        self.assertIsNotNone(m)
        self.assertEqual(m.group(1), "Toggle floating")


class TestFullPipeline(unittest.TestCase):
    def test_full_pipeline(self):
        """Parse the real keybinds.lua and verify output."""
        keybinds_path = Path(__file__).resolve().parents[2] / ".config" / "hypr" / "modules" / "keybinds.lua"
        if not keybinds_path.is_file():
            self.skipTest("keybinds.lua not found")

        binds = gkh.parse_keybinds(keybinds_path)
        self.assertGreater(len(binds), 0)

        rendered = gkh.render(binds)
        self.assertTrue(rendered.startswith("-- Auto-generated"))
        self.assertIn("return {", rendered)

        for b in binds:
            self.assertEqual(len(b), 4)
            self.assertTrue(b[0], "Empty key")
            self.assertTrue(b[1], "Empty description")
            self.assertTrue(b[2], "Empty action")
            self.assertTrue(b[3], "Empty group")

    def test_render_output_syntax(self):
        """Render a small set of binds and verify Lua syntax."""
        binds = [
            ("SUPER + T", "[Apps] Launch kitty", 'exec_cmd("kitty")', "Apps"),
            ("SUPER + F", "[Windows] Fullscreen", "window.fullscreen()", "Windows"),
        ]
        rendered = gkh.render(binds)
        self.assertIn("SUPER + T", rendered)
        self.assertIn("SUPER + F", rendered)

        with tempfile.NamedTemporaryFile(mode="w", suffix=".lua", delete=False) as f:
            f.write(rendered)
            f.flush()
            result = subprocess.run(
                ["lua", "-e", f'local d = dofile("{f.name}"); assert(#d == 2)'],
                capture_output=True, text=True
            )
            if result.returncode != 0 and "not found" not in result.stderr:
                self.fail(f"Lua syntax check failed: {result.stderr}")

    def test_deduplication(self):
        """Duplicate key+group pairs are collapsed."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".lua", delete=False) as f:
            f.write("""
-- ═══ Apps ════════════════════════════════════════
hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty"))
""")
            f.flush()
            binds = gkh.parse_keybinds(Path(f.name))
            keys = [b[0] for b in binds]
            self.assertEqual(keys.count("SUPER + T"), 1)

    def test_desc_annotation(self):
        """@desc annotation overrides auto-generated description."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".lua", delete=False) as f:
            f.write("""
-- ═══ Apps ════════════════════════════════════════
hl.bind(mod .. " + T", hl.dsp.exec_cmd("kitty"))
-- @desc My custom description
hl.bind(mod .. " + F", hl.dsp.exec_cmd("firefox"))
""")
            f.flush()
            binds = gkh.parse_keybinds(Path(f.name))
            # @desc on line 3 applies to bind on line 2 (SUPER + T)
            self.assertEqual(binds[0][1], "My custom description")
            # SUPER + F gets auto-generated description
            self.assertIn("Launch firefox", binds[1][1])

    def test_group_override(self):
        """@group annotation overrides display category."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".lua", delete=False) as f:
            f.write("""
-- ═══ Focus ════════════════════════════════════════
-- @group Windows
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
""")
            f.flush()
            binds = gkh.parse_keybinds(Path(f.name))
            self.assertEqual(binds[0][3], "Windows")
            self.assertIn("[Windows]", binds[0][1])

    def test_loop_expansion(self):
        """for loop is expanded to individual entries."""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".lua", delete=False) as f:
            f.write("""
-- ═══ Workspaces ══════════════════════════════════
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end
""")
            f.flush()
            binds = gkh.parse_keybinds(Path(f.name))
            keys = [b[0] for b in binds]
            self.assertIn("SUPER + 1", keys)
            self.assertIn("SUPER + 9", keys)
            self.assertEqual(len(binds), 9)


if __name__ == "__main__":
    unittest.main()
