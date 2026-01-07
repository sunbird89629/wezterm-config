local wezterm = require("wezterm") ---@type Wezterm
local M = {}

function M.setup(config)
    -- =========== 基础外观 ===========
    config.window_background_opacity = 0.9
    config.window_close_confirmation = "NeverPrompt"
    config.macos_window_background_blur = 40
    config.default_cursor_style = "BlinkingBar"
    config.font_size = 24
    config.color_scheme = "Glacier"

    config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"

    --  config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
    local border_width = "2px";
    local border_color = "#C06DD8";
    config.window_frame = {
        border_left_width = border_width,
        border_right_width = border_width,
        border_top_height = border_width,
        border_bottom_height = border_width,
        border_left_color = border_color,
        border_right_color = border_color,
        border_top_color = border_color,
        border_bottom_color = border_color
    }

    -- =========== Command Palette 外观 ===========
    config.command_palette_font = wezterm.font("JetBrains Mono")
    config.command_palette_font_size = 28.0

    config_tab_bar_colors(config)
end

function config_tab_bar_colors(config)
    -- config.use_fancy_tab_bar = false
    config.colors = {
        tab_bar = {
            background = "#0c0f1a", -- bar background
            active_tab = {
                bg_color = "#263859",
                fg_color = "#e8f1ff",
                intensity = "Bold"
            },
            inactive_tab = {
                bg_color = "#121725",
                fg_color = "#8a94aa"
            },
            inactive_tab_hover = {
                bg_color = "#1a2135",
                fg_color = "#c5d7ff",
                italic = true
            },
            new_tab = {
                bg_color = "#0c0f1a",
                fg_color = "#5d7cff"
            },
            new_tab_hover = {
                bg_color = "#1f2b45",
                fg_color = "#e8f1ff",
                italic = true
            }
        }
    }
end

return M
