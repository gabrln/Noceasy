#!/bin/bash
hyprctl dispatch exit
sleep 0.5
systemctl --user stop noctalia-shell
