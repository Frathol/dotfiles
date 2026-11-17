#!/bin/bash
CHOICE=$(printf "🃏 Play Full Scoundrel (Digital Deck TUI)\n🧮 Physical Deck Tracker (Wofi Companion)" | wofi --dmenu --prompt "Scoundrel Mode:" --width 400 --height 160)

case "$CHOICE" in
*"Digital Deck"*)
  kitty --class scoundrel-tui -T "Scoundrel Roguelike" -e ~/.local/bin/scoundrel_tui.py
  ;;
*"Physical Deck"*)
  ~/.local/bin/scoundrel.sh
  ;;
esac
