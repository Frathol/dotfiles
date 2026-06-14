#!/bin/bash
sleep 2

killall -9 xdg-desktop-portal-hyprland xdg-desktop-portal

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
