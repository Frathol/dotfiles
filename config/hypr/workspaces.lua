-- ~/.config/hypr/workspaces.lua
---@module 'hl'

hl.on("hyprland.start", function()
	for i = 1, 6 do
		hl.exec_cmd("hyprctl keyword workspace " .. i .. ",monitor:eDP-1")
	end
	for i = 7, 10 do
		hl.exec_cmd("hyprctl keyword workspace " .. i .. ",monitor:HDMI-A-1")
	end
end)
