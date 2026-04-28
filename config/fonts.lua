local wezterm = require("wezterm")
local platform = require("utils.platform")

local M = {}

function M.setup(config)
    -- Font configuration
    local font_family = "JetBrainsMono Nerd Font"
    local font_size = platform.is_mac and 23 or 9.75

    config.font = wezterm.font_with_fallback({{
        family = font_family,
        weight = "Medium"
    }, {
        family = "Sarasa Term SC"
    }})
    config.font_size = font_size

    -- config.treat_east_asian_ambiguous_width_as_wide = true

    config.line_height = 0.95
    config.cell_width = 0.95

    -- ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
    config.freetype_load_target = "Normal" ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
    config.freetype_render_target = "Normal" ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'

    -- Command Palette font settings (previously in appearance.lua)
    config.command_palette_font_size = 18
    -- config.command_palette_font = wezterm.font("JetBrains Mono")
end

return M
