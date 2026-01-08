local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    local toggle_terminal = wezterm.plugin.require("https://github.com/zsh-sage/toggle_terminal.wez")
    
    toggle_terminal.apply_to_config(config, {
        key = "j",             -- 使用 'j' 键
        mods = "CMD",          -- 使用 CMD 键 (CMD + j)
        direction = "Down",    -- 底部弹出 (修正为 "Down")
        size = { Percent = 35 }, -- 占用 35% 高度
        zoom = {
            auto_zoom_toggle_terminal = false,
            auto_zoom_invoker_pane = true,
            remember_zoomed = true,
        }
    })
end

return M
