local wezterm = require("wezterm") ---@type Wezterm
local M = {}

local function config_base_style(config)
    -- =========== 基础外观 ===========
    -- config.window_background_opacity = 0.4
    -- config.macos_window_background_blur = 80
    config.window_close_confirmation = "NeverPrompt"
    config.default_cursor_style = "BlinkingBar"
    -- config.color_scheme = "Marrakesh (light) (terminal.sexy)"
    -- config.color_scheme = 'Monokai Pro Ristretto (Gogh)'
    -- config.color_scheme = 'Material'
    -- config.color_scheme = 'MaterialDesignColors'
    -- config.color_scheme = 'nord-light'
    -- config.color_scheme = 'Medallion'
    -- config.color_scheme = 'Mocha (dark) (terminal.sexy)'
    -- config.color_scheme = 'Sat (Gogh)'
    -- config.color_scheme = 'Seafoam Pastel'
    config.color_scheme = 'Abernathy'
    -- config.color_scheme = 'Atelier Lakeside Light (base16)'

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
end

local function config_tab_bar_style(config)
    -- config.use_fancy_tab_bar = false
    config.underline_thickness = "2px"
    config.colors = {
        -- 命令面板整体背景与前景
        command_palette_bg_color = "#11111b", -- 更深的黑色背景
        command_palette_fg_color = "#ffffff", -- 纯白文字

        -- 搜索匹配的高亮（保持醒目）
        quick_select_label_bg = { Color = "#f9e2af" }, -- 亮黄色
        quick_select_label_fg = { Color = "#11111b" },

        -- 选中项的高亮（大幅提升对比度）
        -- 这里使用明亮的蓝色或紫色背景，让选中状态极其明显
        selection_bg = "#585b70", -- 较浅的灰色背景作为次级区分
        -- 注意：WezTerm 的命令面板选中行通常使用 selection_bg
        -- 为了绝对的对比度，我们可以尝试更鲜艳的颜色
        selection_bg = "#89b4fa", -- 明亮的蓝色
        selection_fg = "#11111b", -- 选中行使用深色文字

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

local function config_cammand_palette_style(config)
    config.command_palette_rows = 12
    config.command_palette_bg_color = "#11111b"
    config.command_palette_fg_color = "#ffffff"
end

function M.setup(config)
    config_base_style(config)
    config_tab_bar_style(config)
    config_cammand_palette_style(config)
end
return M
