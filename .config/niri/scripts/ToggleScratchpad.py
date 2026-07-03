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
import os

LOG_FILE = "/tmp/scratchpad.log"

def log(msg):
    try:
        with open(LOG_FILE, "a") as f:
            f.write(f"{msg}\n")
    except Exception:
        pass

def niri_json(*args):
    result = subprocess.run(["niri", "msg", "-j"] + list(args),
                            capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def niri_action(*args):
    subprocess.run(["niri", "msg", "action"] + list(args), check=True)


def main():
    log(f"--- Run with args: {sys.argv[1:]} ---")
    if len(sys.argv) < 3:
        log("Error: Too few arguments")
        print("Usage: ToggleScratchpad.py <app_id> <spawn_command...>")
        sys.exit(1)

    app_id = sys.argv[1]
    spawn_cmd = sys.argv[2:]

    try:
        # Query current windows and workspaces
        windows = niri_json("windows")
        workspaces = niri_json("workspaces")

        # Find the currently focused workspace
        focused_ws = next((ws for ws in workspaces if ws.get("is_focused")), None)
        if not focused_ws:
            log("Error: Could not determine focused workspace")
            print("Could not determine focused workspace")
            sys.exit(1)

        focused_ws_id = focused_ws.get("id")
        log(f"Focused workspace ID: {focused_ws_id}")

        # Find the scratchpad window
        target = next((w for w in windows if w.get("app_id") == app_id), None)

        if not target:
            log(f"Window '{app_id}' not found. Spawning: {spawn_cmd}")
            # App not running — spawn it
            subprocess.Popen(spawn_cmd)
            return

        target_id = target.get("id")
        target_ws_id = target.get("workspace_id")
        log(f"Found target window {target_id} on workspace {target_ws_id}")

        if target_ws_id == focused_ws_id:
            log(f"Hiding window {target_id} to workspace 'scratchpad'")
            # Window is on the current workspace — hide it by moving to named "scratchpad" workspace
            niri_action("move-window-to-workspace", "--window-id", str(target_id), "scratchpad")
        else:
            dest_ws = str(focused_ws.get("name") or focused_ws_id)
            log(f"Bringing window {target_id} to current workspace {dest_ws}")
            # Window is hidden — bring it to the current workspace and focus it
            niri_action("move-window-to-workspace", "--window-id", str(target_id), dest_ws)
            niri_action("focus-window", "--id", str(target_id))
    except Exception as e:
        log(f"Exception occurred: {str(e)}")
        import traceback
        log(traceback.format_exc())


if __name__ == "__main__":
    main()
