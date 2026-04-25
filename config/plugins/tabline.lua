local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

    tabline.setup({
        options = {
            icons_enabled = true,
            theme = 'GruvboxDark',
            -- tabs_enabled = true,
            -- section_separators = {
            --     left = '',
            --     right = ''
            -- },
            -- component_separators = {
            --     left = '',
            --     right = ''
            -- },
            tab_separators = {
                left = '',
                right = ' '
                -- left = wezterm.nerdfonts.pl_left_hard_divider,
                -- right = wezterm.nerdfonts.pl_right_hard_divider
            },
            -- ,
            -- 覆盖主题颜色以增强区分度
            theme_overrides = {
                tab_active = {
                    fg = '#11111b',
                    bg = '#f96407'
                }, -- 活动标签：橙色背景，深色文字
                tab_inactive = {
                    fg = '#cdd6f4',
                    bg = '#313244'
                } -- 非活动标签：深灰色背景，浅色文字
            }
        },
        sections = {
            tab_active = {'index', {
                'parent',
                padding = 0
            }, '/', {
                'cwd',
                padding = {
                    left = 0,
                    right = 1
                }
            }, {
                'zoomed',
                padding = 0
            }},
            -- tabline_a = {'mode'},
            -- tabline_b = {'workspace'},
            -- tabline_c = { 'cwd' },        -- 保留您之前的 CWD
            tabline_x = {'ram', 'cpu'}, -- 增加系统监控
            tabline_y = {},
            tabline_z = {} -- 保留您之前的 Hostname
        },
        extensions = {}
    })

    tabline.apply_to_config(config)
end

return M
