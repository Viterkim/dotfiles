local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"

config.canonicalize_pasted_newlines = "LineFeed"

config.initial_cols = 300
config.initial_rows = 100

config.font_size = 13
config.color_scheme = "tokyonight-storm"
config.font = wezterm.font("CaskaydiaCove NF")

config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

local function spawn_tab_to_right(window, pane)
	local tabs = window:mux_window():tabs_with_info()
	local active_index = 1

	for i, item in ipairs(tabs) do
		if item.is_active then
			active_index = i
			break
		end
	end

	local moves_left = #tabs - active_index

	window:perform_action(act.SpawnTab("CurrentPaneDomain"), pane)

	for _ = 1, moves_left do
		window:perform_action(act.MoveTabRelative(-1), pane)
	end
end

config.keys = {
	-- Tab/Pane Management
	-- This closes the current pane. If it's the last pane, the tab closes.
	{ key = "w", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },
	{
		key = "f",
		mods = "ALT",
		action = wezterm.action_callback(function(window, pane)
			spawn_tab_to_right(window, pane)
		end),
	},

	-- Splitting Panes (New sub)
	{ key = "b", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "p", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- Pane Navigation (Sub-things)
	{ key = "c", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "d", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "h", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "j", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },

	-- Tab back and forth
	{ key = "n", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "e", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "i", mods = "ALT", action = wezterm.action.MoveTabRelative(-1) },
	{ key = "o", mods = "ALT", action = wezterm.action.MoveTabRelative(1) },

	-- Hardcoded Tab Switching (1-6)
	{ key = "1", mods = "ALT", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "ALT", action = wezterm.action.ActivateTab(5) },

	-- Tab Renaming
	{
		key = "l",
		mods = "ALT",
		action = wezterm.action.PromptInputLine({
			description = "Rename Tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Copy Paste
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(wezterm.action.ClearSelection, pane)
			else
				window:perform_action(wezterm.action.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
}

return config
