local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    -- 1. 核心配置：伪造更大的行间距
    -- 我们将字号设为 32px 来撑开行高，但通过下面的 scale = 0.75 让文字保持 24px 大小
    config.command_palette_rows = 24
    config.command_palette_font_size = 34

    -- 2. 颜色配置 (顶层字段)
    config.command_palette_bg_color = '#11111b'
    config.command_palette_fg_color = '#ffffff'

    -- 3. 字体回退与缩放 (实现伪造间距的关键)
    config.command_palette_font = wezterm.font_with_fallback({{
        family = 'Material Design Icons'
    }, {
        family = 'JetBrainsMono Nerd Font',
        scale = 0.6
    }})
end

return M
