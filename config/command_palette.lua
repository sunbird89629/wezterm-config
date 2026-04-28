local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    config.command_palette_rows = 24
    config.command_palette_font_size = 28

    config.command_palette_bg_color = '#11111b'
    config.command_palette_fg_color = '#ffffff'

    config.command_palette_font = wezterm.font_with_fallback({
        { family = 'JetBrainsMono Nerd Font', weight = 'Medium' },
        { family = 'Sarasa Term SC' },
    })
end

return M
