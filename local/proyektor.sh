#!/bin/bash

PILIHAN=$(printf "🖥️ Extend\n📽️ Mirror\n💻 Just Laptop Please :)" | wofi --dmenu --prompt "Display Mode" --width 360 --height 200)

case "$PILIHAN" in
*"Extend"*)
  cat <<'EOF' >~/.config/hypr/monitors.lua
-- ~/.config/hypr/monitors.lua
---@module 'hl'

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144",
    position = "0x0",
    scale = 1,
    vrr = 0,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "1920x0",
    scale = 1,
    vrr = 0,
})
EOF
  hyprctl reload
  notify-send "Display Mode" "Extends Mode"
  ;;
*"Mirror"*)
  cat <<'EOF' >~/.config/hypr/monitors.lua
-- ~/.config/hypr/monitors.lua
---@module 'hl'

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144",
    position = "0x0",
    scale = 1,
    vrr = 0,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "0x0",
    scale = 1,
    mirror = "eDP-1",
})
EOF
  hyprctl reload
  notify-send "Display Mode" "Mirror Mode"
  ;;
*"Laptop Saja"*)
  cat <<'EOF' >~/.config/hypr/monitors.lua
-- ~/.config/hypr/monitors.lua
---@module 'hl'

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@144",
    position = "0x0",
    scale = 1,
    vrr = 0,
})

hl.monitor({
    output = "HDMI-A-1",
    disabled = true,
})
EOF
  hyprctl reload
  notify-send "Display Mode" "Just Laptop :)"
  ;;
esac
