local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    -- 1. 基础尺寸与布局
    config.command_palette_rows = 24 -- 减少行数让布局更紧凑
    config.command_palette_font_size = 24 -- 稍微加大字号提高可读性
    config.command_palette_bg_color = '#1e1e2e'
    --  config.command_palette_font='#1e1e2e'
end

return M
