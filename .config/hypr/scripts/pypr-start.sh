#!/bin/bash
# Wrapper to start pyprland daemon after Hyprland socket is ready
# Called from autostart.lua with hl.exec_cmd

sleep 1
exec pypr
