-- ~/.config/hypr/hyprland.lua
---@module 'hl'

-- ################
-- ### MONITORS ###
-- ################
require("monitors")
require("workspaces")

-- ###################
-- ### MY PROGRAMS ###
-- ###################
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "wofi --show drun"
local firefox     = "firefox"
local mainMod     = "SUPER"

-- #############################
-- ### ENVIRONMENT VARIABLES ###
-- #############################
hl.env("XCURSOR_SIZE", 24)
hl.env("HYPRCURSOR_SIZE", 24)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("WLR_NO_HARDWARE_CURSORS", 1)
hl.env("WLR_RENDERER_ALLOW_SOFTWARE", 1)
hl.env("WLR_DRM_NO_ATOMIC", 1)
hl.env("__NV_PRIME_RENDER_OFFLOAD", 1)
hl.env("_JAVA_AWT_WM_NONREPARENTING", 1)

-- #####################
-- ### LOOK AND FEEL ###
-- #####################
hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 4,
        border_size = 2,
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
        col = {
            active_border = "rgba(ffffff33)",
            inactive_border = "rgba(00000000)",
        },
    },

    decoration = {
        rounding = 0,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
        bezier = {
            "easeOutQuint, 0.23, 1, 0.32, 1",
            "easeInOutCubic, 0.65, 0.05, 0.36, 1",
            "linear, 0, 0, 1, 1",
            "almostLinear, 0.5, 0.5, 0.75, 1",
            "quick, 0.15, 0, 0.1, 1",
        },
        animation = {
            "global, 1, 10, default",
            "border, 1, 5.39, easeOutQuint",
            "windows, 1, 4.79, easeOutQuint",
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%",
            "windowsOut, 1, 1.49, linear, popin 87%",
            "fadeIn, 1, 1.73, almostLinear",
            "fadeOut, 1, 1.46, almostLinear",
            "fade, 1, 3.03, quick",
            "layers, 1, 3.81, easeOutQuint",
            "layersIn, 1, 4, easeOutQuint, fade",
            "layersOut, 1, 1.5, linear, fade",
            "fadeLayersIn, 1, 1.79, almostLinear",
            "fadeLayersOut, 1, 1.39, almostLinear",
            "workspaces, 1, 1.94, almostLinear, fade",
            "workspacesIn, 1, 1.21, almostLinear, fade",
            "workspacesOut, 1, 1.94, almostLinear, fade",
            "zoomFactor, 1, 7, quick",
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0.6,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            scroll_factor = 0.7,
        },
        accel_profile = "flat",
        force_no_accel = false,
    },
})

-- ################
-- ### GESTURES ###
-- ################
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- ###################
-- ### KEYBINDINGS ###
-- ###################
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit")
)
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind("CTRL + " .. mainMod .. " + F", hl.dsp.exec_cmd(firefox))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.local/bin/wallpicker.sh"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("CTRL + " .. mainMod .. " + P", hl.dsp.exec_cmd("nwg-displays"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

-- Clipboard History (Super + Shift + V)
hl.bind(
    mainMod .. " + SHIFT + V",
    hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy")
)

-- Screenshot Area (Super + Alt + S) - Dioptimalkan dengan tee agar cukup 1x seleksi slurp
hl.bind(
    mainMod .. " + ALT + S",
    hl.dsp.exec_cmd(
        'grim -g "$(slurp)" - | tee ~/Pictures/Screenshots/$(date +\'%Y-%m-%d-%H%M%S_screenshot.png\') | wl-copy && notify-send "Area Screenshot Copied & Saved"'
    )
)

-- Screenshot Full (Super + Print)
hl.bind(
    mainMod .. " + Print",
    hl.dsp.exec_cmd(
        'grim - | tee ~/Pictures/Screenshots/$(date +\'%Y-%m-%d-%H%M%S_screenshot.png\') | wl-copy && notify-send "Full Screenshot Copied & Saved"'
    )
)

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Move active window to left/right monitor (Dikembalikan dari hyprland.conf)
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:l"))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:r"))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces with mainMod + scroll (Fix bug hl.dsp.focus string)
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("hyprctl dispatch workspace e+1"))
hl.bind(mainMod .. " + mouse_up", hl.dsp.exec_cmd("hyprctl dispatch workspace e-1"))
-- hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("hyprctl dispatch workspace r+1"))
-- hl.bind(mainMod .. " + mouse_up", hl.dsp.exec_cmd("hyprctl dispatch workspace r-1"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia & Brightness Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && swayosd-client --output-volume mute-toggle"),
    { locked = true }
)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true })

-- Playerctl Media Keys
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ####################
-- ### WINDOW RULES ###
-- ####################
hl.window_rule({
    name = "suppress-maximize-events",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = {
        class = "hyprland-run",
    },
    move = { 20, "monitor_h-120" },
    float = true,
})

-- #################
-- ### AUTOSTART ###
-- #################
hl.on("hyprland.start", function()
    -- 1. Grafis & Wallpaper
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd('sleep 1 && hyprctl hyprpaper wallpaper ",/home/frathol/Pictures/Wallpaper/current_wallpaper.png"')
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")

    -- 2. Input & Tray Applets (Diberi jeda 2 detik agar System Tray Waybar siap lebih dulu dan tidak memblokir pojok kiri)
    hl.exec_cmd("sleep 2 && nm-applet --indicator")
    hl.exec_cmd("sleep 2 && blueman-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- 3. Services & Portals
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start graphical-session.target")
    hl.exec_cmd("~/.config/hypr/xdg.sh")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
end)
