local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

    tabline.setup({
        options = {
            icons_enabled = true,
            theme = 'Catppuccin Mocha',
            tabs_enabled = true,
            section_separators = {
                left = '',
                right = ''
            },
            component_separators = {
                left = '',
                right = ''
            },
            tab_separators = {
                left = '',
                right = ''
            },
            -- 覆盖主题颜色以增强区分度
            theme_overrides = {
                tab_active = {
                    fg = '#11111b',
                    bg = '#fab387'
                }, -- 活动标签：橙色背景，深色文字
                tab_inactive = {
                    fg = '#cdd6f4',
                    bg = '#313244'
                } -- 非活动标签：深灰色背景，浅色文字
            }
        },
        sections = {
            tabline_a = {'mode'},
            -- tabline_b = {'workspace'},
            -- tabline_c = { 'cwd' },        -- 保留您之前的 CWD
            tabline_x = {'ram', 'cpu'}, -- 增加系统监控
            tabline_y = {},
            tabline_z = {'hostname'} -- 保留您之前的 Hostname
        },
        extensions = {}
    })

    tabline.apply_to_config(config)
end

return M
