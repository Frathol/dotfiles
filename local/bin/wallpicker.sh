#!/bin/bash

DIR="$HOME/Pictures/Wallpaper"
PILIHAN=$(ls "$DIR" | grep -v "current_wallpaper.png" | wofi --dmenu --prompt "Choose Wallpaper")

if [ -n "$PILIHAN" ]; then
  ln -sf "$DIR/$PILIHAN" "$DIR/current_wallpaper.png"

  hyprctl hyprpaper preload "$DIR/current_wallpaper.png"
  hyprctl hyprpaper wallpaper ",$DIR/current_wallpaper.png"

  sleep 1
  hyprctl hyprpaper unload all
fi
