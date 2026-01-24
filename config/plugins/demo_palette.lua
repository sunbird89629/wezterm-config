local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- 定义一组演示命令
-- 每个命令包含：id, label_text, key_text (快捷键), category (分类), icon, color
local commands = {
  { id = 'reload',   category = 'System',  icon = '', color = '#fab387', label = 'Reload Configuration', desc = 'Reload wezterm.lua', key = 'Ctrl+Shift+R' },
  { id = 'debug',    category = 'System',  icon = '', color = '#f38ba8', label = 'Show Debug Overlay',   desc = 'View logs and debug info', key = 'Ctrl+Shift+L' },
  
  { id = 'split_h',  category = 'Pane',    icon = '', color = '#89b4fa', label = 'Split Horizontally',   desc = 'Split current pane right', key = 'Cmd+D' },
  { id = 'split_v',  category = 'Pane',    icon = '', color = '#89b4fa', label = 'Split Vertically',     desc = 'Split current pane down',  key = 'Cmd+Shift+D' },
  { id = 'zoom',     category = 'Pane',    icon = '', color = '#89b4fa', label = 'Toggle Zoom',          desc = 'Maximize current pane',    key = 'Cmd+Z' },
  
  { id = 'git_s',    category = 'Git',     icon = '', color = '#a6e3a1', label = 'Git Status',           desc = 'Show git status popup',    key = 'None' },
  { id = 'git_l',    category = 'Git',     icon = '', color = '#a6e3a1', label = 'Git Log',              desc = 'View git commit history',  key = 'None' },
  
  { id = 'theme',    category = 'Look',    icon = '', color = '#cba6f7', label = 'Select Theme',         desc = 'Change color scheme',      key = 'None' },
}

-- 辅助函数：构建显示的 Label
local function build_label(cmd, max_width)
  -- 计算对齐需要的空格
  -- 这是一个简单的估算，因为字体宽度不一定一致，但在等宽字体下效果最好
  local label_width = #cmd.label
  local desc_width = #cmd.desc
  local key_width = #cmd.key
  
  -- 布局策略： Icon + Label + (padding) + Description + (padding) + Key
  -- 我们尝试把 Key 放到右边。InputSelector 的总宽度取决于 WezTerm 窗口大小，这里我们假设一个固定宽度来做对齐
  local target_width = 80 
  local padding_1 = 2
  
  -- 描述文字颜色更淡一些
  local text_elements = {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { Color = cmd.color } },
    { Text = cmd.icon .. '  ' },
    
    { Attribute = { Intensity = 'Normal' } },
    { Foreground = { Color = '#cdd6f4' } }, -- 主文本颜色
    { Text = cmd.label },
    
    { Text = string.rep(' ', padding_1) },
    
    { Foreground = { Color = '#6c7086' } }, -- 描述文本颜色 (灰色)
    { Attribute = { Intensity = 'Half' } }, -- 变淡
    { Text = cmd.desc },
    { Attribute = { Intensity = 'Normal' } },
  }
  
  -- 如果有快捷键，添加右对齐效果
  if cmd.key ~= 'None' then
     -- 计算目前已占用的字符数 (Icon=3, padding=2)
     local current_len = 3 + #cmd.label + padding_1 + #cmd.desc
     local pad_len = target_width - current_len - #cmd.key
     if pad_len < 2 then pad_len = 2 end
     
     table.insert(text_elements, { Text = string.rep(' ', pad_len) })
     table.insert(text_elements, { Foreground = { Color = '#fab387' } }) -- 快捷键颜色 (橙色)
     table.insert(text_elements, { Text = cmd.key })
  end
  
  return wezterm.format(text_elements)
end

function M.setup(config)
    local choices = {}
    for _, cmd in ipairs(commands) do
        table.insert(choices, {
            id = cmd.id,
            label = build_label(cmd, 80)
        })
    end

    local key_binding = {
        key = 'f',
        mods = 'CMD|SHIFT',
        action = wezterm.action.InputSelector {
            title = wezterm.format({
                { Attribute = { Intensity = 'Bold' } },
                { Foreground = { Color = '#cba6f7' } },
                { Text = '   Command Palette Demo ' },
            }),
            choices = choices,
            fuzzy = true,
            -- 设置模糊搜索描述文字
            fuzzy_description = 'Search commands: ',
            
            action = wezterm.action_callback(function(window, pane, id, label)
                if not id then return end
                
                -- 演示执行逻辑
                if id == 'reload' then
                    window:perform_action(act.ReloadConfiguration, pane)
                elseif id == 'debug' then
                    window:perform_action(act.ShowDebugOverlay, pane)
                elseif id == 'split_h' then
                    window:perform_action(act.SplitHorizontal { domain = 'CurrentPaneDomain' }, pane)
                elseif id == 'split_v' then
                    window:perform_action(act.SplitVertical { domain = 'CurrentPaneDomain' }, pane)
                elseif id == 'zoom' then
                    window:perform_action(act.TogglePaneZoomState, pane)
                elseif id == 'theme' then
                    window:perform_action(act.InputSelector {
                        action = wezterm.action_callback(function(window, pane, id, label)
                            if id then
                                window:set_config_overrides({ color_scheme = id })
                            end
                        end),
                        choices = wezterm.get_builtin_color_schemes(),
                        fuzzy = true,
                        title = 'Select Theme',
                    }, pane)
                else
                    wezterm.log_info('Selected: ' .. id)
                    window:toast_notification('Demo Palette', 'You selected: ' .. label, nil, 2000)
                end
            end),
        }
    }

    -- 插入到用户的 keys 配置中
    if config.keys == nil then config.keys = {} end
    table.insert(config.keys, key_binding)
end

return M
