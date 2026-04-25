local wezterm = require("wezterm") ---@type Wezterm
local M = {}

local function config_base_style(config)
    -- =========== 基础外观 ===========
    config.window_close_confirmation = "NeverPrompt"
    config.default_cursor_style = "BlinkingBar"
    config.color_scheme = 'Abernathy'
    config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"

    config.window_padding = {
        left = 30,
        right = 30,
        top = 30,
        bottom = 30
    }
end

local function config_tab_bar_style(config)
    config.underline_thickness = "2px"

    -- Ensure colors table exists without overwriting existing entries
    config.colors = config.colors or {}

    -- Quick select labels
    config.colors.quick_select_label_bg = {
        Color = "#f9e2af"
    }
    config.colors.quick_select_label_fg = {
        Color = "#11111b"
    }

    -- Selection colors
    config.colors.selection_bg = "#89b4fa"
    config.colors.selection_fg = "#11111b"

    -- Split color
    config.colors.split = "#5d7cff"

    -- Tab bar styling
    config.colors.tab_bar = {
        background = "#0c0f1a",
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
end

function M.setup(config)
    config_base_style(config)
    config_tab_bar_style(config)
end
return M
