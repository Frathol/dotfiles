 #!/bin/bash
# Ambil screenshot
grim -g "$(slurp)" ~/Pictures/Screenshots$(date +'%Y-%m-%d-%H%M%S_screenshot.png')
# Paksa bunuh slurp dan kawan-kawan
killall -9 slurp grim
# Pancing portal agar sadar tugasnya selesai
systemctl --user restart xdg-desktop-portal-hyprland
# Kirim notifikasi
notify-send "Screenshot Saved"
