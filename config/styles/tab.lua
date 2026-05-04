local M = {}

function M.setup(config)
    config.hide_tab_bar_if_only_one_tab = true
    config.show_new_tab_button_in_tab_bar = false
    config.use_fancy_tab_bar = true

    -- Ensure colors table exists without overwriting existing entries
    config.colors = config.colors or {}

    -- Catppuccin Mocha palette
    local mocha = {
        base = "#1e1e2e",
        mantle = "#181825",
        surface0 = "#313244",
        surface1 = "#45475a",
        overlay0 = "#6c7086",
        text = "#cdd6f4",
        subtext0 = "#a6adc8",
        blue = "#89b4fa"
    }

    -- Quick select labels
    config.colors.quick_select_label_bg = {
        Color = mocha.blue
    }
    config.colors.quick_select_label_fg = {
        Color = mocha.base
    }

    -- Selection colors
    config.colors.selection_bg = mocha.blue
    config.colors.selection_fg = mocha.base

    -- Split color
    config.colors.split = mocha.surface1

    -- Minimal underline tab bar (Catppuccin Mocha)
    config.colors.tab_bar = {
        background = mocha.mantle,
        active_tab = {
            bg_color = mocha.mantle,
            fg_color = mocha.text,
            intensity = "Bold",
            underline = "Single"
        },
        inactive_tab = {
            bg_color = mocha.mantle,
            fg_color = mocha.overlay0
        },
        inactive_tab_hover = {
            bg_color = mocha.mantle,
            fg_color = mocha.subtext0,
            italic = true
        },
        new_tab = {
            bg_color = mocha.mantle,
            fg_color = mocha.surface1
        },
        new_tab_hover = {
            bg_color = mocha.mantle,
            fg_color = mocha.blue,
            italic = true
        }
    }
end

return M
