#!/bin/bash
# Wofi Scoundrel Card Game Tracker (HP, Weapon, Monster Limit & Auto-Damage)

STATE_FILE="/tmp/scoundrel_state"

init_game() {
  echo "HP=20" >"$STATE_FILE"
  echo "WEAPON=0" >>"$STATE_FILE"
  echo "LIMIT=0" >>"$STATE_FILE"
  echo "RUN_LOCK=0" >>"$STATE_FILE"
}

[ ! -f "$STATE_FILE" ] && init_game

parse_card() {
  case "${1^^}" in
  J) echo 11 ;;
  Q) echo 12 ;;
  K) echo 13 ;;
  A) echo 14 ;;
  *) [[ "$1" =~ ^[0-9]+$ ]] && echo "$1" || echo 0 ;;
  esac
}

while true; do
  source "$STATE_FILE"

  if [ "$WEAPON" -eq 0 ]; then
    W_STATUS="None"
  elif [ "$LIMIT" -eq 0 ]; then
    W_STATUS="♦️ $WEAPON (Max: Any)"
  else
    W_STATUS="♦️ $WEAPON (Max: <$LIMIT)"
  fi

  [ "$RUN_LOCK" -eq 1 ] && R_STATUS="🚫 Cannot Run" || R_STATUS="✅ Can Run"

  PROMPT="❤️ $HP/20 | ⚔️ $W_STATUS | $R_STATUS"

  CHOICE=$(printf "⚔️ Fight with Weapon\n👊 Fight Barehanded\n🛡️ Equip Weapon (♦️)\n🧪 Drink Potion (♥️)\n🏃 Run from Room\n🔄 New Game (Reset)" | wofi --dmenu --prompt "$PROMPT" --width 440 --height 290)

  [ -z "$CHOICE" ] && exit 0

  case "$CHOICE" in
  *"Fight with Weapon"*)
    if [ "$WEAPON" -eq 0 ]; then
      notify-send "⚠️ No Weapon" "Equip a ♦️ Diamond weapon first or fight barehanded."
      continue
    fi
    CARD=$(printf "2\n3\n4\n5\n6\n7\n8\n9\n10\nJ (11)\nQ (12)\nK (13)\nA (14)" | wofi --dmenu --prompt "Monster Value (♠️/♣️):" --width 300 --height 320 | awk '{print $1}')
    VAL=$(parse_card "$CARD")
    [ "$VAL" -lt 2 ] || [ "$VAL" -gt 14 ] && continue

    if [ "$LIMIT" -gt 0 ] && [ "$VAL" -ge "$LIMIT" ]; then
      notify-send "🚫 Weapon Degraded!" "Weapon limit is <$LIMIT. Monster ($VAL) is too strong! Fight barehanded."
      continue
    fi

    DMG=$((VAL - WEAPON))
    [ "$DMG" -lt 0 ] && DMG=0
    HP=$((HP - DMG))
    LIMIT=$VAL
    RUN_LOCK=0

    if [ "$HP" -le 0 ]; then
      notify-send "💀 YOU DIED!" "Slain by Monster ($VAL). Final HP: $HP"
      init_game
    else
      notify-send "⚔️ Monster Slain ($VAL)" "Blocked: $WEAPON | Damage: -$DMG\n❤️ HP: $HP/20 | New Limit: <$LIMIT"
      printf "HP=%d\nWEAPON=%d\nLIMIT=%d\nRUN_LOCK=%d\n" "$HP" "$WEAPON" "$LIMIT" "$RUN_LOCK" >"$STATE_FILE"
    fi
    ;;

  *"Fight Barehanded"*)
    CARD=$(printf "2\n3\n4\n5\n6\n7\n8\n9\n10\nJ (11)\nQ (12)\nK (13)\nA (14)" | wofi --dmenu --prompt "Barehanded vs Monster:" --width 300 --height 320 | awk '{print $1}')
    VAL=$(parse_card "$CARD")
    [ "$VAL" -lt 2 ] || [ "$VAL" -gt 14 ] && continue

    HP=$((HP - VAL))
    RUN_LOCK=0

    if [ "$HP" -le 0 ]; then
      notify-send "💀 YOU DIED!" "Slain barehanded by Monster ($VAL). Final HP: $HP"
      init_game
    else
      notify-send "👊 Barehanded Hit (-$VAL)" "❤️ HP: $HP/20 | Weapon ($W_STATUS) unchanged"
      printf "HP=%d\nWEAPON=%d\nLIMIT=%d\nRUN_LOCK=%d\n" "$HP" "$WEAPON" "$LIMIT" "$RUN_LOCK" >"$STATE_FILE"
    fi
    ;;

  *"Equip Weapon"*)
    CARD=$(printf "2\n3\n4\n5\n6\n7\n8\n9\n10" | wofi --dmenu --prompt "Equip Diamond (♦️ 2-10):" --width 300 --height 280)
    VAL=$(parse_card "$CARD")
    [ "$VAL" -lt 2 ] || [ "$VAL" -gt 10 ] && continue

    WEAPON=$VAL
    LIMIT=0
    RUN_LOCK=0
    printf "HP=%d\nWEAPON=%d\nLIMIT=%d\nRUN_LOCK=%d\n" "$HP" "$WEAPON" "$LIMIT" "$RUN_LOCK" >"$STATE_FILE"
    notify-send "🛡️ Weapon Equipped" "♦️ $WEAPON equipped (Limit reset to Any)"
    ;;

  *"Drink Potion"*)
    CARD=$(printf "2\n3\n4\n5\n6\n7\n8\n9\n10" | wofi --dmenu --prompt "Heal Value (♥️ 2-10):" --width 300 --height 280)
    VAL=$(parse_card "$CARD")
    [ "$VAL" -lt 2 ] || [ "$VAL" -gt 10 ] && continue

    OLD_HP=$HP
    HP=$((HP + VAL))
    [ "$HP" -gt 20 ] && HP=20
    RUN_LOCK=0
    printf "HP=%d\nWEAPON=%d\nLIMIT=%d\nRUN_LOCK=%d\n" "$HP" "$WEAPON" "$LIMIT" "$RUN_LOCK" >"$STATE_FILE"
    notify-send "🧪 Potion Drank (+$VAL)" "❤️ HP: $OLD_HP -> $HP/20"
    ;;

  *"Run from Room"*)
    if [ "$RUN_LOCK" -eq 1 ]; then
      notify-send "🚫 Cannot Run!" "You cannot run from two rooms in a row."
    else
      RUN_LOCK=1
      printf "HP=%d\nWEAPON=%d\nLIMIT=%d\nRUN_LOCK=%d\n" "$HP" "$WEAPON" "$LIMIT" "$RUN_LOCK" >"$STATE_FILE"
      notify-send "🏃 Avoided Room" "Placed 4 cards at the bottom. Must face the next room!"
    fi
    ;;

  *"New Game"*)
    init_game
    notify-send "🔄 Scoundrel Reset" "❤️ HP: 20/20 | ⚔️ Weapon: None"
    ;;
  esac
done
