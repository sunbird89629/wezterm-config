local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    -- 1. 核心配置 (严格按照用户要求的 24/24 比例)
    config.command_palette_rows = 24
    config.command_palette_font_size = 24.0

    -- 2. 颜色配置 (顶层字段)
    config.command_palette_bg_color = '#11111b'
    config.command_palette_fg_color = '#ffffff'

    -- 3. 字体回退
    config.command_palette_font = wezterm.font_with_fallback({{
        family = 'Material Design Icons',
        weight = 'Bold'
    }})
end

return M
