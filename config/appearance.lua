local wezterm = require("wezterm") ---@type Wezterm
local M = {}

function M.setup(config)
    -- =========== 基础外观 ===========
    -- config.window_background_opacity = 0.4
    -- config.macos_window_background_blur = 80
    config.window_close_confirmation = "NeverPrompt"

    config.default_cursor_style = "BlinkingBar"
    config.font_size = 24
    -- config.color_scheme = "Marrakesh (light) (terminal.sexy)"
    -- config.color_scheme = 'Monokai Pro Ristretto (Gogh)'
    -- config.color_scheme = 'Material'
    -- config.color_scheme = 'MaterialDesignColors'
    -- config.color_scheme = 'nord-light'
    -- config.color_scheme = 'Medallion'
    -- config.color_scheme = 'Mocha (dark) (terminal.sexy)'
    -- config.color_scheme = 'Sat (Gogh)'
    config.color_scheme = 'Seafoam Pastel'

    config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"

    --     config.window_frame = {
    --         border_left_width = '0.5cell',
    --         border_right_width = '0.5cell',
    --         border_bottom_height = '0.25cell',
    --         border_top_height = '0.25cell',
    --         border_left_color = 'purple',
    --         border_right_color = 'purple',
    --         border_bottom_color = 'purple',
    --         border_top_color = 'purple',    
    --    }
    config.window_padding = {
        left = 30,
        right = 30,
        top = 30,
        bottom = 30
    }
    -- local border_width = "2px";
    -- local border_color = "#C06DD8";
    -- config.window_frame = {
    --     border_left_width = 10,
    --     border_right_width = 10
    -- }
    -- =========== Command Palette 外观 ===========
    config.command_palette_font = wezterm.font("JetBrains Mono")
    config.command_palette_font_size = 16.0

    config_tab_bar_colors(config)
end

function config_tab_bar_colors(config)
    -- config.use_fancy_tab_bar = false
    config.underline_thickness = "2px"
    config.colors = {
        -- Overrides for the Command Palette / Input Selector
        -- Making it visually distinct with a dark modal feel even if theme is light
        quick_select_label_bg = { Color = "#fab387" },
        quick_select_label_fg = { Color = "#1e1e2e" },
        
        -- Since WezTerm doesn't have a simple "command_palette_bg" key in the colors table 
        -- (it uses the color scheme's background), we can't easily force it dark 
        -- without changing the whole scheme or using complex overrides.
        -- But we can ensure the selection highlights are nice.
        selection_bg = "#585b70",
        selection_fg = "#cdd6f4",

        split = "#5d7cff",
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
