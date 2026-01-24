local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- 定义一组演示命令
local commands = {{
    id = 'reload',
    category = 'System',
    icon = '',
    color = 'Red',
    label = 'Reload Configuration',
    desc = 'Reload wezterm.lua',
    key = 'Ctrl+Shift+R'
}, {
    id = 'debug',
    category = 'System',
    icon = '',
    color = 'Yellow',
    label = 'Show Debug Overlay',
    desc = 'View logs and debug info',
    key = 'Ctrl+Shift+L'
}, {
    id = 'split_h',
    category = 'Pane',
    icon = '',
    color = 'Blue',
    label = 'Split Horizontally',
    desc = 'Split current pane right',
    key = 'Cmd+D'
}, {
    id = 'split_v',
    category = 'Pane',
    icon = '',
    color = 'Blue',
    label = 'Split Vertically',
    desc = 'Split current pane down',
    key = 'Cmd+Shift+D'
}, {
    id = 'zoom',
    category = 'Pane',
    icon = '',
    color = 'Purple',
    label = 'Toggle Zoom',
    desc = 'Maximize current pane',
    key = 'Cmd+Z'
}, {
    id = 'git_s',
    category = 'Git',
    icon = '',
    color = 'Green',
    label = 'Git Status',
    desc = 'Show git status popup',
    key = 'None'
}, {
    id = 'git_l',
    category = 'Git',
    icon = '',
    color = 'Green',
    label = 'Git Log',
    desc = 'View git commit history',
    key = 'None'
}, {
    id = 'theme',
    category = 'Look',
    icon = '',
    color = 'Fuchsia',
    label = 'Select Theme',
    desc = 'Change color scheme',
    key = 'None'
}, {
    id = 'monitor',
    category = 'System',
    icon = '',
    color = 'Aqua',
    label = 'Process Monitor',
    desc = 'Show btop/htop',
    key = 'None'
}, {
    id = 'file',
    category = 'System',
    icon = '',
    color = 'Yellow',
    label = 'File Explorer',
    desc = 'Open file manager',
    key = 'None'
}}

-- 辅助函数：构建显示的 Label
-- width: 允许的最大字符宽度
local function build_label(cmd, width, scheme_is_dark)
    -- 简单判断颜色可见性（如果需要更复杂逻辑可以扩展）
    -- 这里我们使用 AnsiColor 或者具体的 hex，尽量保持通用

    local label_width = #cmd.label
    local desc_width = #cmd.desc
    local key_width = #cmd.key

    -- 基础布局计算
    -- Icon(4) + Label + Padding + Desc + Padding + Key
    local icon_len = 4
    local min_padding = 2

    -- 动态计算中间的 padding
    -- 我们希望 Key 靠右对齐
    -- 剩余空间 = 总宽度 - Icon - Label - Desc - Key - MinPadding
    local fixed_content_len = icon_len + label_width + min_padding + desc_width + min_padding + key_width
    local dynamic_padding = width - fixed_content_len

    if dynamic_padding < 0 then
        dynamic_padding = 0
    end

    -- 构建文本元素
    local elements = {}

    -- 1. Icon (带颜色)
    table.insert(elements, {
        Foreground = {
            AnsiColor = cmd.color
        }
    })
    table.insert(elements, {
        Text = cmd.icon .. '   '
    })

    -- 2. Label (使用默认前景色，自动适配明/暗主题)
    table.insert(elements, 'ResetAttributes') -- Reset color and attributes
    table.insert(elements, {
        Attribute = {
            Intensity = 'Bold'
        }
    })
    table.insert(elements, {
        Text = cmd.label
    })
    table.insert(elements, {
        Attribute = {
            Intensity = 'Normal'
        }
    })

    -- 3. Description (灰色/变淡)
    -- 使用固定的间距分开 Label 和 Description
    table.insert(elements, {
        Text = '  '
    })

    -- 描述文字颜色：在 Light 模式下要是深灰，Dark 模式下要是浅灰
    -- 我们可以使用 AnsiColor Grey 或者根据主题判断，这里简单使用 'Grey' (通常对应 bright black)
    table.insert(elements, {
        Foreground = {
            AnsiColor = 'Grey'
        }
    })
    table.insert(elements, {
        Attribute = {
            Intensity = 'Half'
        }
    }) -- Faint
    table.insert(elements, {
        Text = cmd.desc
    })
    table.insert(elements, {
        Attribute = {
            Intensity = 'Normal'
        }
    })

    -- 4. Right Align Padding + Shortcut
    if cmd.key ~= 'None' then
        table.insert(elements, {
            Text = string.rep(' ', dynamic_padding)
        })
        table.insert(elements, {
            Foreground = {
                AnsiColor = 'Yellow'
            }
        })
        table.insert(elements, {
            Text = cmd.key
        })
    end

    return wezterm.format(elements)
end

function M.activate(window, pane)
    -- 获取当前窗口尺寸以计算对齐
    local dims = window:get_dimensions()
    -- 假设 Command Palette 占据屏幕宽度的 40-50% 左右（WezTerm 默认行为），或者我们以 cell 为单位估算
    -- InputSelector 默认是居中，宽度约为 60-80 chars，但也取决于内容。
    -- 我们这里设定一个期望的宽度用于对齐。
    local width = 80

    -- 检测当前主题是亮色还是暗色（用于微调颜色，如果需要）
    -- 暂时假设默认

    local choices = {}
    for _, cmd in ipairs(commands) do
        table.insert(choices, {
            id = cmd.id,
            label = build_label(cmd, width, true)
        })
    end

    window:perform_action(act.InputSelector {
        action = wezterm.action_callback(function(window, pane, id, label)
            if not id then
                return
            end

            if id == 'reload' then
                window:perform_action(act.ReloadConfiguration, pane)
            elseif id == 'debug' then
                window:perform_action(act.ShowDebugOverlay, pane)
            elseif id == 'split_h' then
                window:perform_action(act.SplitHorizontal {
                    domain = 'CurrentPaneDomain'
                }, pane)
            elseif id == 'split_v' then
                window:perform_action(act.SplitVertical {
                    domain = 'CurrentPaneDomain'
                }, pane)
            elseif id == 'zoom' then
                window:perform_action(act.TogglePaneZoomState, pane)
            elseif id == 'theme' then
                window:perform_action(act.InputSelector {
                    action = wezterm.action_callback(function(window, pane, id, label)
                        if id then
                            window:set_config_overrides({
                                color_scheme = id
                            })
                        end
                    end),
                    choices = wezterm.get_builtin_color_schemes(),
                    fuzzy = true,
                    title = 'Select Theme'
                }, pane)
            else
                window:toast_notification('Demo', 'Selected: ' .. label, nil, 2000)
            end
        end),

        title = wezterm.format({{
            Attribute = {
                Intensity = 'Bold'
            }
        }, {
            Foreground = {
                AnsiColor = 'Purple'
            }
        }, {
            Text = '   Command Palette '
        }}),
        choices = choices,
        fuzzy = true,
        fuzzy_description = 'Search: '
        -- 增加一些样式配置 (WezTerm Nightly 支持)
        -- alphabetical = false,
    }, pane)
end

function M.setup(config)
    -- 注意：这里我们需要把 key binding 改为调用 action_callback 以便动态执行 M.activate
    local key_binding = {
        key = 'f',
        mods = 'CMD|SHIFT',
        action = wezterm.action_callback(function(window, pane)
            M.activate(window, pane)
        end)
    }

    config.keys = config.keys or {}
    -- 移除旧的绑定（如果有），或者直接覆盖
    -- 简单起见，我们假设用户会重新加载配置，这里直接插入
    table.insert(config.keys, key_binding)
end

return M
