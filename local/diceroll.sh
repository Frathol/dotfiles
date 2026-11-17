#!/bin/bash
# Roll multiple multi-sided dice (NdX) using Wofi and Mako notification

INPUT=$(printf "1d4\n1d6\n2d6\n3d6\n1d8\n1d10\n1d12\n1d20\n2d20\n1d100" | wofi --dmenu --prompt "Roll Dice (e.g. 3d6, 2d20, d20):" --width 320 --height 300)

# Exit if cancelled or empty
[ -z "$INPUT" ] && exit 0

# Parse optional dice count and required sides (supports 3d6, d20, or 20)
if [[ "$INPUT" =~ ^([0-9]*)[dD]?([0-9]+)$ ]]; then
  COUNT="${BASH_REMATCH[1]:-1}"
  SIDES="${BASH_REMATCH[2]}"

  # Validate positive values and cap count at 100 to prevent notification overflow
  if [ "$COUNT" -gt 0 ] && [ "$COUNT" -le 100 ] && [ "$SIDES" -gt 0 ]; then
    ROLLS=()
    TOTAL=0

    # -r allows repeating numbers (independent dice rolls)
    while read -r VAL; do
      ROLLS+=("$VAL")
      ((TOTAL += VAL))
    done < <(shuf -r -i 1-"$SIDES" -n "$COUNT")

    if [ "$COUNT" -eq 1 ]; then
      notify-send "🎲 Dice Roll (1d$SIDES)" "Result: $TOTAL"
    else
      ROLL_LIST=$(
        IFS=", "
        echo "${ROLLS[*]}"
      )
      notify-send "🎲 Dice Roll (${COUNT}d${SIDES})" "Rolls: [$ROLL_LIST]\nTotal: $TOTAL"
    fi
  else
    notify-send "⚠️ Invalid Dice" "Enter 1-100 dice with at least 1 side."
  fi
else
  notify-send "⚠️ Invalid Format" "Use NdX format (e.g., 3d6, 2d20, or 20)."
fi
