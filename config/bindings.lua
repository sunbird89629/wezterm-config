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

function M.setup(config)
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
        key = "F12",
        mods = "NONE",
        action = act.ShowDebugOverlay
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
    }}
end
return M
