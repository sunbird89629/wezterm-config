local wezterm = require("wezterm")
local M = {}

local function pane_cwd_path(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then
        return nil
    end

    -- 新版可能直接是 Url 对象
    if type(cwd) == 'userdata' or type(cwd) == 'table' then
        return cwd.file_path
    end

    -- 旧版是 URI 字符串：用 url.parse（20240127+）解析
    if type(cwd) == 'string' and wezterm.url and wezterm.url.parse then
        local ok, url = pcall(wezterm.url.parse, cwd)
        if ok and url and url.file_path then
            return url.file_path
        end
    end

    -- 最后兜底：手动把 file://... 去掉（可能不处理 %20 之类编码）
    if type(cwd) == 'string' then
        return (cwd:gsub('^file://[^/]*', ''))
    end

    return nil
end

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
            text = text .. pane:get_text_from_semantic_zone(next_zone)
        end
    end

    window:copy_to_clipboard(text, 'Clipboard')
    window:toast_notification('WezTerm', 'Copied last command and output', nil, 2000)
end

function M.setup(config)
    config.leader = { key = "l", mods = "CMD", timeout_milliseconds = 1000 }
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
        key = "O",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(function(win, pane)
            local cwd = pane_cwd_path(pane)
            win:perform_action(act.SpawnCommandInNewWindow({
                cwd = cwd,
                args = {'/opt/homebrew/bin/yazi'}
            }), pane)
        end)
    }, {
        key = "L",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(copy_last_command_output)
    }}
end
return M
