local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
    bar.apply_to_config(config, {
        position = "top",
        separator = {
            space = 1,
            left_icon = "",
            right_icon = "",
            field_icon = ""
        },
        padding = {
            left = 1,
            right = 1,
            tabs = {
                left = 2,
                right = 2
            }
        },
        modules = {
            -- tabs = {
            --     -- 只保留最基础的颜色配置（用 ANSI 色号）
            --     active_tab_fg = 4,
            --     inactive_tab_fg = 6,
            --     new_tab_fg = 2
            -- },
            -- 其余模块全部关闭
            workspace = {
                enabled = false
            },
            leader = {
                enabled = false
            },
            zoom = {
                enabled = false
            },
            pane = {
                enabled = false
            },
            username = {
                enabled = false
            },
            hostname = {
                enabled = true
            },
            clock = {
                enabled = false
            },
            cwd = {
                enabled = true,
                icon = ""
            },
            spotify = {
                enabled = false
            }
        }
    })
end

return M
