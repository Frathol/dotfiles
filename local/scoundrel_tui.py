#!/usr/bin/env python3
import copy
import curses
import json
import os
import random
import subprocess

STATS_FILE = os.path.expanduser("~/.local/share/scoundrel_stats.json")

RANKS = {
    2: "2",
    3: "3",
    4: "4",
    5: "5",
    6: "6",
    7: "7",
    8: "8",
    9: "9",
    10: "10",
    11: "J",
    12: "Q",
    13: "K",
    14: "A",
}

SUITS = {
    "S": ("♠", "MONSTER", 2),
    "C": ("♣", "MONSTER", 2),
    "D": ("♦", "WEAPON", 3),
    "H": ("♥", "POTION", 1),
}


def notify(title, msg):
    try:
        subprocess.Popen(
            ["notify-send", title, msg],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        pass


def load_stats():
    default = {"best": None, "wins": 0, "played": 0, "streak": 0}
    if os.path.exists(STATS_FILE):
        try:
            with open(STATS_FILE, "r") as f:
                data = json.load(f)
                default.update(data)
        except Exception:
            pass
    return default


def save_stats(stats):
    os.makedirs(os.path.dirname(STATS_FILE), exist_ok=True)
    try:
        with open(STATS_FILE, "w") as f:
            json.dump(stats, f)
    except Exception:
        pass


class ScoundrelGame:
    def __init__(self):
        self.stats = load_stats()
        self.history = []
        self.show_deck_modal = False
        self.cursor = 0
        self.reset()

    def save_snapshot(self):
        state = {
            "hp": self.hp,
            "weapon": self.weapon,
            "weapon_limit": self.weapon_limit,
            "slain_stack": list(self.slain_stack),
            "barehand_mode": self.barehand_mode,
            "can_run": self.can_run,
            "potion_used_in_room": self.potion_used_in_room,
            "resolved_in_room": self.resolved_in_room,
            "room_num": self.room_num,
            "deck": list(self.deck),
            "room": list(self.room),
            "discard": list(self.discard),
            "logs": list(self.logs),
            "cursor": self.cursor,
        }
        self.history.append(copy.deepcopy(state))
        if len(self.history) > 30:
            self.history.pop(0)

    def undo(self):
        if not self.history or self.game_over:
            self.log("[!] Nothing to undo.")
            return
        state = self.history.pop()
        self.hp = state["hp"]
        self.weapon = state["weapon"]
        self.weapon_limit = state["weapon_limit"]
        self.slain_stack = state["slain_stack"]
        self.barehand_mode = state["barehand_mode"]
        self.can_run = state["can_run"]
        self.potion_used_in_room = state["potion_used_in_room"]
        self.resolved_in_room = state["resolved_in_room"]
        self.room_num = state["room_num"]
        self.deck = state["deck"]
        self.room = state["room"]
        self.discard = state["discard"]
        self.logs = state["logs"]
        self.cursor = min(state["cursor"], max(0, len(self.room) - 1))
        self.log("[↺] Undid last action.")

    def reset(self):
        self.hp = 20
        self.max_hp = 20
        self.weapon = 0
        self.weapon_limit = 0
        self.slain_stack = []
        self.barehand_mode = False
        self.can_run = True
        self.potion_used_in_room = False
        self.resolved_in_room = 0
        self.room_num = 1
        self.game_over = False
        self.victory = False
        self.last_card_bonus = 0
        self.cursor = 0
        self.history = []
        self.discard = []
        self.logs = [
            "Welcome to Scoundrel! Resolve 3 of 4 cards to advance, or press [R] to Run.",
            "Tip: Press [D] to inspect remaining cards in the deck, or [U] to Undo a mistake.",
        ]

        self.deck = []
        for s in ["S", "C"]:
            for v in range(2, 15):
                self.deck.append((v, s))
        for s in ["D", "H"]:
            for v in range(2, 11):
                self.deck.append((v, s))
        random.shuffle(self.deck)

        self.room = []
        self.deal_room(initial=True)

    def log(self, text):
        self.logs.insert(0, text)
        if len(self.logs) > 8:
            self.logs.pop()

    def deal_room(self, initial=False):
        while len(self.room) < 4 and len(self.deck) > 0:
            self.room.append(self.deck.pop(0))
        self.resolved_in_room = 0
        self.potion_used_in_room = False
        self.cursor = min(self.cursor, max(0, len(self.room) - 1))
        if not initial:
            self.room_num += 1

    def get_score(self):
        if self.victory:
            return self.hp + self.last_card_bonus
        rem_monsters = sum(v for v, s in (self.deck + self.room) if s in ("S", "C"))
        return self.hp - rem_monsters

    def can_use_weapon_on(self, val):
        if self.weapon == 0 or self.barehand_mode:
            return False
        if self.weapon_limit == 0 or val < self.weapon_limit:
            return True
        return False

    def analyze_card(self, card):
        val, suit = card
        r_str = RANKS[val]
        s_icon = SUITS[suit][0]
        if suit == "D":
            return (
                f"Equip ♦{val}",
                f"Replaces current weapon with ♦{val} (Limit reset to Any).",
                False,
            )
        if suit == "H":
            if self.potion_used_in_room:
                return (
                    "Waste (+0 HP)",
                    "Second potion in this room! Will be discarded for +0 HP.",
                    False,
                )
            heal = min(self.max_hp - self.hp, val)
            new_hp = min(self.max_hp, self.hp + val)
            return (
                f"Heal +{heal} HP",
                f"Restores +{heal} HP (HP: {self.hp} -> {new_hp}/20).",
                False,
            )
        if self.can_use_weapon_on(val):
            dmg = max(0, val - self.weapon)
            new_hp = self.hp - dmg
            lethal = new_hp <= 0
            badge = f"!! LETHAL (-{dmg}) !!" if lethal else f"Weapon: -{dmg} HP"
            detail = f"Attack {r_str}{s_icon} ({val}) with ♦{self.weapon}: Blocks {min(val, self.weapon)}, takes -{dmg} HP (HP: {self.hp} -> {new_hp}). New Limit < {val}."
            return badge, detail, lethal
        else:
            dmg = val
            new_hp = self.hp - dmg
            lethal = new_hp <= 0
            badge = f"!! LETHAL (-{dmg}) !!" if lethal else f"Barehand: -{dmg} HP"
            reason = (
                "Barehand Mode ON"
                if self.barehand_mode
                else (
                    "No Weapon"
                    if self.weapon == 0
                    else f"Monster {val} >= Limit {self.weapon_limit}"
                )
            )
            detail = f"Fight {r_str}{s_icon} ({val}) Barehanded ({reason}): Takes full -{dmg} HP (HP: {self.hp} -> {new_hp})."
            return badge, detail, lethal

    def run_from_room(self):
        if self.game_over:
            return
        if self.resolved_in_room > 0 or len(self.room) < 4:
            self.log("[!] Cannot Run: You already played a card in this room.")
            return
        if not self.can_run:
            self.log("[!] Cannot Run: You cannot run from two rooms in a row.")
            return

        self.save_snapshot()
        random.shuffle(self.room)
        self.deck.extend(self.room)
        self.room = []
        self.can_run = False
        self.deal_room()
        self.log(
            f"[»] Avoided room! 4 cards shuffled to bottom of deck. Entered Room #{self.room_num}."
        )

    def record_endgame(self, victory):
        sc = self.get_score()
        self.stats["played"] += 1
        if victory:
            self.stats["wins"] += 1
            self.stats["streak"] += 1
        else:
            self.stats["streak"] = 0
        if self.stats["best"] is None or sc > self.stats["best"]:
            self.stats["best"] = sc
        save_stats(self.stats)
        return sc

    def play_card(self, idx):
        if self.game_over or idx < 0 or idx >= len(self.room):
            return

        self.save_snapshot()
        val, suit = self.room.pop(idx)
        self.discard.append((val, suit))
        self.cursor = min(self.cursor, max(0, len(self.room) - 1))
        r_str = RANKS[val]
        s_icon = SUITS[suit][0]
        self.resolved_in_room += 1
        self.last_card_bonus = 0

        if suit == "D":
            self.weapon = val
            self.weapon_limit = 0
            self.slain_stack = []
            self.barehand_mode = False
            self.log(f"[♦] Equipped {r_str}{s_icon} (Power {val}, Max Target: Any).")

        elif suit == "H":
            if not self.potion_used_in_room:
                old_hp = self.hp
                self.hp = min(self.max_hp, self.hp + val)
                self.potion_used_in_room = True
                if len(self.deck) == 0 and len(self.room) == 0 and old_hp == 20:
                    self.last_card_bonus = val
                self.log(
                    f"[♥] Drank {r_str}{s_icon}: Healed +{self.hp - old_hp} HP (HP: {self.hp}/20)."
                )
            else:
                self.log(
                    f"[!] Discarded {r_str}{s_icon} for +0 HP (Max 1 potion per room)."
                )

        else:
            if self.can_use_weapon_on(val):
                dmg = max(0, val - self.weapon)
                self.hp -= dmg
                self.weapon_limit = val
                self.slain_stack.append(f"{r_str}{s_icon}")
                self.log(
                    f"[⚔] Slain {r_str}{s_icon} ({val}) with ♦{self.weapon}! Blocked {min(val, self.weapon)}, took -{dmg} HP. Limit < {val}."
                )
            else:
                self.hp -= val
                reason = "Barehand Mode" if self.barehand_mode else "Unarmed/Degraded"
                self.log(
                    f"[✕] Fought {r_str}{s_icon} ({val}) barehanded ({reason})! Took -{val} HP."
                )
                self.barehand_mode = False

        if self.hp <= 0:
            self.game_over = True
            self.victory = False
            sc = self.record_endgame(False)
            self.log(
                f"[DEAD] You were slain! Final Score: {sc} (Best: {self.stats['best']}). Press [N] for New Game."
            )
            notify("Scoundrel: You Died", f"Final Score: {sc}")
            return

        if len(self.deck) == 0 and len(self.room) == 0:
            self.game_over = True
            self.victory = True
            sc = self.record_endgame(True)
            self.log(
                f"[VICTORY] Dungeon Cleared! Final Score: {sc} (Best: {self.stats['best']})!"
            )
            notify("Scoundrel: Victory!", f"Dungeon Cleared! Score: {sc}")
            return

        if (self.resolved_in_room == 3 and len(self.deck) > 0) or len(self.room) == 0:
            self.can_run = True
            carried = len(self.room)
            self.deal_room()
            self.log(
                f"[»] Room cleared! Entered Room #{self.room_num} ({carried} card carried over, {len(self.deck)} in deck)."
            )


def safe_add(stdscr, y, x, text, attr=0):
    max_y, max_x = stdscr.getmaxyx()
    if y < 0 or y >= max_y or x >= max_x:
        return
    if x < 0:
        text = text[-x:]
        x = 0
    if x + len(text) > max_x:
        text = text[: max_x - x]
    if text:
        try:
            stdscr.addstr(y, x, text, attr)
        except curses.error:
            pass


def draw_box(stdscr, y, x, h, w, title="", attr=0, title_attr=0):
    safe_add(stdscr, y, x, "╭" + "─" * (w - 2) + "╮", attr)
    for row in range(1, h - 1):
        safe_add(stdscr, y + row, x, "│" + " " * (w - 2) + "│", attr)
    safe_add(stdscr, y + h - 1, x, "╰" + "─" * (w - 2) + "╯", attr)
    if title:
        t_str = f" {title} "
        safe_add(
            stdscr, y, x + 2, t_str, title_attr if title_attr else attr | curses.A_BOLD
        )


def draw_card(stdscr, y, x, idx, card, selected, game):
    val, suit = card
    r_str = RANKS[val]
    s_icon, s_type, c_idx = SUITS[suit]
    badge, _, lethal = game.analyze_card(card)

    card_color = curses.color_pair(c_idx)
    border_attr = (curses.color_pair(4) | curses.A_BOLD) if selected else card_color

    # Selector Header
    hdr = f"► [{idx + 1}] ◄" if selected else f"  [{idx + 1}]  "
    hdr_attr = (curses.color_pair(4) | curses.A_BOLD) if selected else curses.A_BOLD
    safe_add(stdscr, y, x + 6, hdr, hdr_attr)

    # Card Artpip
    pip_label = f"Power {val:>2}" if suit in ("S", "C", "D") else f"Heal +{val:>2}"
    lines = [
        "╭─────────────────╮",
        f"│ {r_str:<2}            {s_icon} │",
        "│                 │",
        f"│    {s_icon} {s_type:<7}    │",
        f"│    {pip_label}    │",
        "│                 │",
        f"│ {s_icon}            {r_str:>2} │",
        "╰─────────────────╯",
    ]
    for i, ln in enumerate(lines):
        if i in (0, 7):
            safe_add(stdscr, y + 1 + i, x, ln, border_attr)
        else:
            safe_add(stdscr, y + 1 + i, x, "│", border_attr)
            safe_add(
                stdscr,
                y + 1 + i,
                x + 1,
                ln[1:-1],
                card_color | (curses.A_BOLD if i == 3 else 0),
            )
            safe_add(stdscr, y + 1 + i, x + 18, "│", border_attr)

    # Action Preview Pill
    b_attr = (
        (curses.color_pair(1) | curses.A_BOLD | curses.A_BLINK)
        if lethal
        else (curses.color_pair(4) | curses.A_BOLD if selected else curses.A_DIM)
    )
    safe_add(stdscr, y + 9, x, f"{badge:^19}"[:19], b_attr)


def draw_deck_modal(stdscr, oy, ox, game):
    draw_box(
        stdscr,
        oy + 4,
        ox + 2,
        22,
        82,
        "DUNGEON DECK INSPECTOR (UNORDERED REMAINING CARDS)",
        curses.color_pair(4),
        curses.color_pair(4) | curses.A_BOLD,
    )
    rem_set = set(game.deck)
    room_set = set(game.room)

    safe_add(
        stdscr,
        oy + 6,
        ox + 5,
        "Legend: [In Dungeon Deck]    (Currently in Room)    · Already Slain/Used",
        curses.A_BOLD,
    )

    suit_order = [
        ("S", "♠ Spades (Monsters) ", range(2, 15), 2),
        ("C", "♣ Clubs (Monsters)  ", range(2, 15), 2),
        ("D", "♦ Diamonds (Weapons)", range(2, 11), 3),
        ("H", "♥ Hearts (Potions)  ", range(2, 11), 1),
    ]

    for row_i, (s_code, label, r_range, c_pair) in enumerate(suit_order):
        y = oy + 8 + row_i * 3
        safe_add(stdscr, y, ox + 5, label, curses.color_pair(c_pair) | curses.A_BOLD)
        cur_x = ox + 26
        for v in r_range:
            rk = RANKS[v]
            if (v, s_code) in rem_set:
                token = f"[{rk}]"
                attr = curses.color_pair(c_pair) | curses.A_BOLD
            elif (v, s_code) in room_set:
                token = f"({rk})"
                attr = curses.color_pair(4) | curses.A_BOLD
            else:
                token = " · "
                attr = curses.A_DIM

            step = 5 if v == 10 else 4
            safe_add(stdscr, y, cur_x, f"{token:<{step}}", attr)
            cur_x += step

    safe_add(
        stdscr,
        oy + 21,
        ox + 5,
        f"Total Remaining in Deck: {len(game.deck)} cards   │   Resolved/Discarded: {len(game.discard)} cards",
        curses.A_BOLD,
    )
    safe_add(
        stdscr,
        oy + 23,
        ox + 21,
        "Press [D], [Space], or [Esc] to return to combat",
        curses.color_pair(4) | curses.A_BOLD,
    )


def main(stdscr):
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_RED, -1)  # Hearts / Danger
    curses.init_pair(2, curses.COLOR_CYAN, -1)  # Monsters (Spades/Clubs)
    curses.init_pair(3, curses.COLOR_YELLOW, -1)  # Weapons (Diamonds)
    curses.init_pair(4, curses.COLOR_GREEN, -1)  # Highlights / Healthy HP
    curses.init_pair(5, curses.COLOR_MAGENTA, -1)  # Accents

    game = ScoundrelGame()
    UI_W, UI_H = 86, 31

    while True:
        stdscr.erase()
        max_y, max_x = stdscr.getmaxyx()

        if max_y < UI_H or max_x < UI_W:
            safe_add(
                stdscr,
                max_y // 2 - 1,
                max(0, (max_x - 52) // 2),
                f"Window too small ({max_x}x{max_y}). Minimum required: {UI_W}x{UI_H}.",
                curses.color_pair(1) | curses.A_BOLD,
            )
            safe_add(
                stdscr,
                max_y // 2 + 1,
                max(0, (max_x - 38) // 2),
                "Resize floating window or press [Q] to quit.",
            )
            stdscr.refresh()
            if stdscr.getch() in (ord("q"), ord("Q")):
                break
            continue

        oy = max(0, (max_y - UI_H) // 2)
        ox = max(0, (max_x - UI_W) // 2)

        # 1. Top Header Bar
        draw_box(stdscr, oy, ox, 3, UI_W, "", curses.color_pair(2))
        safe_add(
            stdscr,
            oy + 1,
            ox + 3,
            "♠ ♥ SCOUNDREL ROGUELIKE ♦ ♣",
            curses.color_pair(3) | curses.A_BOLD,
        )
        best_str = (
            f"{game.stats['best']:+d}" if game.stats["best"] is not None else "None"
        )
        stats_hdr = f"Room #{game.room_num:<2} │ Best: {best_str} │ Wins: {game.stats['wins']}/{game.stats['played']} (Streak: {game.stats['streak']})"
        safe_add(
            stdscr, oy + 1, ox + UI_W - len(stats_hdr) - 3, stats_hdr, curses.A_BOLD
        )

        # 2. Left Panel: Hero & Equipment Status
        draw_box(stdscr, oy + 3, ox, 7, 48, "HERO & EQUIPMENT", curses.color_pair(2))
        hp_clamped = max(0, game.hp)
        hp_bar = "█" * hp_clamped + "░" * (20 - hp_clamped)
        hp_col = (
            curses.color_pair(4)
            if game.hp > 10
            else (curses.color_pair(3) if game.hp > 5 else curses.color_pair(1))
        )
        safe_add(
            stdscr,
            oy + 4,
            ox + 2,
            f"HP   : {game.hp:>2}/20 [{hp_bar}]",
            hp_col | curses.A_BOLD,
        )

        if game.weapon == 0:
            w_txt = "None (Unarmed / Barehanded)"
            chain_txt = "None"
        else:
            lim_txt = (
                f"< {game.weapon_limit} ({RANKS.get(game.weapon_limit, game.weapon_limit)})"
                if game.weapon_limit > 0
                else "Any Monster"
            )
            w_txt = f"♦ {game.weapon:<2} (Max Target: {lim_txt})"
            chain_txt = (
                " -> ".join(game.slain_stack[-5:])
                if game.slain_stack
                else "Fresh Blade"
            )

        safe_add(
            stdscr,
            oy + 5,
            ox + 2,
            f"WPN  : {w_txt}",
            curses.color_pair(3) | curses.A_BOLD,
        )
        safe_add(stdscr, oy + 6, ox + 2, f"SLAIN: {chain_txt}"[:44], curses.A_DIM)

        run_ok = (
            game.can_run
            and game.resolved_in_room == 0
            and len(game.room) == 4
            and not game.game_over
        )
        run_badge = "[✓ READY]" if run_ok else "[✕ LOCKED]"
        pot_badge = "[✓ READY]" if not game.potion_used_in_room else "[✕ USED]"
        safe_add(
            stdscr,
            oy + 7,
            ox + 2,
            f"RUN  : {run_badge:<11} POTION: {pot_badge}",
            curses.A_BOLD,
        )

        mode_str = "[! BAREHAND FORCED !]" if game.barehand_mode else "[AUTO-WEAPON]"
        mode_col = (
            curses.color_pair(1) | curses.A_BOLD
            if game.barehand_mode
            else curses.color_pair(4)
        )
        safe_add(
            stdscr, oy + 8, ox + 2, f"MODE : {mode_str} (Press [B] to toggle)", mode_col
        )

        # 3. Right Panel: Live Dungeon Card Counter (QoL)
        draw_box(
            stdscr,
            oy + 3,
            ox + 50,
            7,
            36,
            f"DUNGEON INTEL ({len(game.deck)} IN DECK)",
            curses.color_pair(2),
        )
        rem_m = [v for v, s in game.deck if s in ("S", "C")]
        rem_w = [v for v, s in game.deck if s == "D"]
        rem_p = [v for v, s in game.deck if s == "H"]
        avg_m = (sum(rem_m) / len(rem_m)) if rem_m else 0.0
        boss_a = sum(1 for v in rem_m if v == 14)
        boss_k = sum(1 for v in rem_m if v == 13)
        boss_q = sum(1 for v in rem_m if v == 12)
        boss_j = sum(1 for v in rem_m if v == 11)

        safe_add(
            stdscr,
            oy + 4,
            ox + 52,
            f"♠/♣ Monsters : {len(rem_m):>2}  (Avg Pow: {avg_m:.1f})",
            curses.color_pair(2),
        )
        safe_add(
            stdscr,
            oy + 5,
            ox + 52,
            f"♦   Weapons  : {len(rem_w):>2}  (Max: ♦{max(rem_w) if rem_w else 0})",
            curses.color_pair(3),
        )
        safe_add(
            stdscr,
            oy + 6,
            ox + 52,
            f"♥   Potions  : {len(rem_p):>2}  (Max: ♥{max(rem_p) if rem_p else 0})",
            curses.color_pair(1),
        )
        safe_add(
            stdscr,
            oy + 7,
            ox + 52,
            f"Bosses Left  : A:{boss_a}  K:{boss_k}  Q:{boss_q}  J:{boss_j}",
            curses.A_BOLD,
        )
        need_res = (
            max(0, min(3, len(game.room)) - game.resolved_in_room)
            if len(game.deck) > 0
            else len(game.room)
        )
        safe_add(
            stdscr,
            oy + 8,
            ox + 52,
            f"To Advance   : Resolve {need_res} more",
            curses.color_pair(4) | curses.A_BOLD,
        )

        # 4. Center Arena: Room Cards
        draw_box(
            stdscr,
            oy + 10,
            ox,
            12,
            UI_W,
            f"CURRENT ROOM ({len(game.room)} CARDS PRESENT)",
            curses.color_pair(2),
        )
        if game.room:
            for i, card in enumerate(game.room):
                draw_card(
                    stdscr, oy + 11, ox + 3 + i * 20, i, card, (i == game.cursor), game
                )
        else:
            msg = "🏆 DUNGEON CLEARED! YOU WIN!" if game.victory else "💀 GAME OVER"
            safe_add(
                stdscr,
                oy + 15,
                ox + (UI_W - len(msg)) // 2,
                msg,
                curses.color_pair(3) | curses.A_BOLD,
            )

        # 5. Selected Card Tactical Preview Box
        draw_box(
            stdscr,
            oy + 22,
            ox,
            3,
            UI_W,
            "TACTICAL ACTION PREVIEW",
            curses.color_pair(3),
        )
        if not game.game_over and game.room and 0 <= game.cursor < len(game.room):
            _, detail, lethal = game.analyze_card(game.room[game.cursor])
            d_attr = (curses.color_pair(1) | curses.A_BOLD) if lethal else curses.A_BOLD
            safe_add(
                stdscr,
                oy + 23,
                ox + 2,
                f"► Card [{game.cursor + 1}]: {detail}"[: UI_W - 4],
                d_attr,
            )
        else:
            safe_add(
                stdscr,
                oy + 23,
                ox + 2,
                f"► Game Over! Final Score: {game.get_score()}  |  Press [N] to start a new dungeon run.",
                curses.color_pair(3) | curses.A_BOLD,
            )

        # 6. Combat Log Panel
        draw_box(stdscr, oy + 25, ox, 5, UI_W, "COMBAT LOG", curses.color_pair(2))
        for i, entry in enumerate(game.logs[:3]):
            attr = curses.A_BOLD if i == 0 else curses.A_DIM
            safe_add(stdscr, oy + 26 + i, ox + 2, f"• {entry}"[: UI_W - 4], attr)

        # 7. Bottom Controls Bar
        ctrl = "[1-4] Play  [◄/►/Enter] Select  [B] Barehand  [R] Run  [U] Undo  [D] Deck  [N] New  [Q] Quit"
        safe_add(
            stdscr,
            oy + 30,
            ox + (UI_W - len(ctrl)) // 2,
            ctrl,
            curses.color_pair(2) | curses.A_BOLD,
        )

        # Modal Overlay if Deck Inspector is active
        if game.show_deck_modal:
            draw_deck_modal(stdscr, oy, ox, game)

        stdscr.refresh()
        ch = stdscr.getch()

        if game.show_deck_modal:
            if ch in (ord("d"), ord("D"), ord(" "), 27, ord("q"), ord("Q")):
                game.show_deck_modal = False
            continue

        if ch in (ord("q"), ord("Q")):
            break
        elif ch in (ord("n"), ord("N")):
            game.reset()
        elif ch in (ord("u"), ord("U")):
            game.undo()
        elif ch in (ord("d"), ord("D"), ord("\t")):
            game.show_deck_modal = True
        elif ch in (ord("b"), ord("B")):
            game.barehand_mode = not game.barehand_mode
            st = (
                "ENABLED (Fighting barehanded!)"
                if game.barehand_mode
                else "DISABLED (Using equipped weapon)"
            )
            game.log(f"[!] Barehand Mode {st}")
        elif ch in (ord("r"), ord("R")):
            game.run_from_room()
        elif ch in (curses.KEY_LEFT, ord("h"), ord("H"), ord("a"), ord("A")):
            if game.room:
                game.cursor = (game.cursor - 1) % len(game.room)
        elif ch in (curses.KEY_RIGHT, ord("l"), ord("L"), ord("f"), ord("F")):
            if game.room:
                game.cursor = (game.cursor + 1) % len(game.room)
        elif ch in (curses.KEY_ENTER, 10, 13, ord(" ")):
            if game.room:
                game.play_card(game.cursor)
        elif ch in (ord("1"), ord("2"), ord("3"), ord("4")):
            idx = ch - ord("1")
            if idx < len(game.room):
                game.cursor = idx
                game.play_card(idx)


if __name__ == "__main__":
    curses.wrapper(main)
