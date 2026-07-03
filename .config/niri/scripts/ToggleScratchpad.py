#!/usr/bin/env python3
"""
ToggleScratchpad.py - Scratchpad toggle for Niri compositor
Uses niri IPC to toggle floating windows between the current workspace
and a hidden "scratchpad" workspace.

Usage: ToggleScratchpad.py <app_id> <spawn_command...>
"""
import json
import subprocess
import sys


def niri_json(*args):
    result = subprocess.run(["niri", "msg", "-j"] + list(args),
                            capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def niri_action(*args):
    subprocess.run(["niri", "msg", "action"] + list(args), check=True)


def main():
    if len(sys.argv) < 3:
        print("Usage: ToggleScratchpad.py <app_id> <spawn_command...>")
        sys.exit(1)

    app_id = sys.argv[1]
    spawn_cmd = sys.argv[2:]

    # Query current windows and workspaces
    windows = niri_json("windows")
    workspaces = niri_json("workspaces")

    # Find the currently focused workspace
    focused_ws = next((ws for ws in workspaces if ws.get("is_focused")), None)
    if not focused_ws:
        print("Could not determine focused workspace")
        sys.exit(1)

    focused_ws_id = focused_ws.get("id")

    # Find the scratchpad window
    target = next((w for w in windows if w.get("app_id") == app_id), None)

    if not target:
        # App not running — spawn it
        subprocess.Popen(spawn_cmd)
        return

    target_id = target.get("id")
    target_ws_id = target.get("workspace_id")

    if target_ws_id == focused_ws_id:
        # Window is on the current workspace — hide it by moving to named "scratchpad" workspace
        # Use --window-id so we don't need to focus it first
        niri_action("move-window-to-workspace", "--window-id", str(target_id), "scratchpad")
    else:
        # Window is hidden — bring it to the current workspace and focus it
        niri_action("move-window-to-workspace", "--window-id", str(target_id),
                    str(focused_ws.get("name") or focused_ws_id))
        niri_action("focus-window", "--id", str(target_id))


if __name__ == "__main__":
    main()
