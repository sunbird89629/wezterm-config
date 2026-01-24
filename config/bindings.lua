local wezterm = require("wezterm")
local M = {}

local function copy_last_command_output(window, pane)
    local zones = pane:get_semantic_zones()
    if not zones then
        return
    end

    local last_input_idx = nil
    -- Find the last Input zone
    for i = #zones, 1, -1 do
        if zones[i].semantic_type == 'Input' then
            last_input_idx = i
            break
        end
    end

    if not last_input_idx then
        window:toast_notification('WezTerm', 'No command found', nil, 2000)
        return
    end

    local text = pane:get_text_from_semantic_zone(zones[last_input_idx])

    -- Check if there is output following it
    if last_input_idx < #zones then
        local next_zone = zones[last_input_idx + 1]
        if next_zone.semantic_type == 'Output' then
            local line_count = next_zone.end_y - next_zone.start_y
            if line_count > 5000 then
                wezterm.log_warn("Output too large (" .. line_count ..
                                     " lines), truncating copy to last 5000 lines to avoid crash.")
                local safe_start_y = next_zone.end_y - 5000
                text = text .. "\n...[Output truncated]...\n" ..
                           pane:get_text_from_region(safe_start_y, 0, next_zone.end_y, next_zone.end_x)
            else
                text = text .. pane:get_text_from_semantic_zone(next_zone)
            end
        end
    end

    window:copy_to_clipboard(text, 'Clipboard')
    window:toast_notification('WezTerm', 'Copied last command and output', nil, 2000)
end

function M.setup(config)
    config.leader = {
        key = "l",
        mods = "CMD",
        timeout_milliseconds = 1000
    }
    local act = wezterm.action
    config.keys = { -- misc / useful
    {
        key = "F2",
        mods = "NONE",
        action = act.ActivateCommandPalette
    }, {
        key = "F3",
        mods = "NONE",
        action = act.ShowLauncher
    }, {
        key = "F4",
        mods = "NONE",
        action = act.ShowLauncherArgs({
            flags = "FUZZY|TABS"
        })
    }, {
        key = "F5",
        mods = "NONE",
        action = act.ShowLauncherArgs({
            flags = "FUZZY|WORKSPACES"
        })
    }, {
        key = "F6",
        mods = "NONE",
        action = "ActivateCopyMode"
    }, {
        key = "[",
        mods = "CMD",
        action = act.ActivateTabRelative(-1)
    }, {
        key = "]",
        mods = "CMD",
        action = act.ActivateTabRelative(1)
    }, {
        key = "P",
        mods = "CMD|SHIFT",
        action = act.ActivateCommandPalette
    }, {
        key = "s",
        mods = "CMD",
        action = act.PaneSelect
    }, {
        key = "L",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(copy_last_command_output)
    }, -- Send standard navigation keys for Cmd+Arrows
    {
        key = "LeftArrow",
        mods = "CMD",
        action = act.SendKey({
            key = "Home"
        })
    }, {
        key = "RightArrow",
        mods = "CMD",
        action = act.SendKey({
            key = "End"
        })
    }, {
        key = "UpArrow",
        mods = "CMD",
        action = act.SendKey({
            key = "PageUp"
        })
    }, {
        key = "DownArrow",
        mods = "CMD",
        action = act.SendKey({
            key = "PageDown"
        })
    }}

    -- Load the custom demo palette plugin
    local demo_palette = require('config.plugins.demo_palette')
    demo_palette.setup(config)
end
return M
