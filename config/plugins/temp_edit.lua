-- 该方法实现如下功能：
-- 1.创建一个临时文件
-- 2.打开一个新的 wezterm 窗口
-- 3.在新窗口中通过 vim 打开第一步创建的临时文件
-- 4.在 vim 中编辑完成，通过 :wq 退出 vim 的时候，把这个临时文件中的内容 copy 到系统剪切板
local wezterm = require("wezterm")
local lib = wezterm.plugin.require("https://github.com/chrisgve/lib.wezterm")
local time = wezterm.time
local act = wezterm.action
local mux = wezterm.mux
local io = require("io")
local os = require("os")

--- Execute a callback periodically.
--- @param interval number Seconds between calls
--- @param callback function The function to call. Return `false` to stop.
--- @return function cancel A function to cancel the timer.
local function set_interval(interval, callback)
    local active = true
    local function runner()
        if not active then
            return
        end
        -- If callback returns explicit false, stop the timer
        if callback() == false then
            active = false
            return
        end
        time.call_after(interval, runner)
    end
    time.call_after(interval, runner)
    return function()
        active = false
    end
end

local function set_window_override(window, k, v)
    local o = window:get_config_overrides() or {}
    o[k] = v
    window:set_config_overrides(o)
end

local function pane_cwd_path(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then
        return nil
    end

    -- 新版可能直接是 Url 对象
    if type(cwd) == 'userdata' or type(cwd) == 'table' then
        return cwd.file_path
    end

    -- 旧版是 URI 字符串：用 url.parse（20240127+）解析
    if type(cwd) == 'string' and wezterm.url and wezterm.url.parse then
        local ok, url = pcall(wezterm.url.parse, cwd)
        if ok and url and url.file_path then
            return url.file_path
        end
    end

    -- 最后兜底：手动把 file://... 去掉（可能不处理 %20 之类编码）
    if type(cwd) == 'string' then
        return (cwd:gsub('^file://[^/]*', ''))
    end

    return nil
end

local temp_file_name = "/tmp/wezterm_temp_file.txt"
-- Read temp file and push its content to clipboard, then clean up.
local function on_pane_exit(window, pane)
    local ok, _, stderr = wezterm.run_child_process({"/bin/sh", "-c", "/usr/bin/pbcopy < " .. temp_file_name})
    if window and pane then
        pcall(function()
            window:perform_action(act.CloseCurrentTab({
                confirm = false
            }), pane)
        end)
    end
end

-- Debugging: Print keys in lib to see what is available
local function log_table_for_debug(target)
    if target then
        for k, v in pairs(target) do
            wezterm.log_error("lib key: " .. k .. " -> " .. tostring(v))
            if type(v) == "table" then
                for k2, v2 in pairs(v) do
                    wezterm.log_error("  " .. k .. "." .. k2 .. " -> " .. tostring(v2))
                end
            end
        end
    else
        wezterm.log_error("target is nil")
    end

end

local function get_activate_screen()
    local screens = wezterm.gui.screens()
    return screens.active or screens.main
end

local function set_as_dialog_window(gui_window)
    set_window_override(gui_window, "enable_tab_bar", false)
    -- set_window_override(gui_window, "window_background_opacity", 0.9)

    local screen = get_activate_screen()

    local target_w = math.floor(screen.width * 0.86)
    local target_h = math.floor(screen.height * 0.86)

    if gui_window then
        gui_window:set_inner_size(target_w, target_h)
    end
end

local function trigger_nvim_edit()
    lib.file_io.write_file(temp_file_name, "")
    local _, pane, window = mux.spawn_window({
        args = {"/bin/zsh", "-lic", "nvim " .. temp_file_name}
    })

    local gui_window = window:gui_window()

    set_as_dialog_window(gui_window)

    local pane_id = pane:pane_id()

    set_interval(0.2, function()
        local ok, live_pane = pcall(mux.get_pane, pane_id)
        if ok and live_pane then
            return true
        else
            on_pane_exit(window, pane)
            return false
        end
    end)
end

-- Helper to write content to a file
local function write_file(path, content)
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
    else
        wezterm.log_error("Failed to write to " .. path)
    end
end

-- Helper to read content from a file
local function read_file(path)
    local f = io.open(path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        return content
    end
    return nil
end

-- If you have shell integration configured, returns the zone around
-- the current cursor position
local function get_zone_around_cursor(pane)
    local cursor = pane:get_cursor_position()
    -- using x-1 here because the cursor may be one cell outside the zone
    local zone = pane:get_semantic_zone_at(cursor.x - 1, cursor.y)
    if zone then
        return pane:get_text_from_semantic_zone(zone)
    end
    return nil
end

local function trigger_cmd_edit(window, pane)
    local original_pane = pane
    local original_pane_id = original_pane:pane_id()

    -- Generate a unique temp file path
    local temp_file_path = "/tmp/wezterm_edit_" .. tostring(original_pane_id) .. "_" .. os.time() .. ".txt"

    -- 1. Grab text
    local initial_text = ""
    local cursor = original_pane:get_cursor_position()
    local zones = original_pane:get_semantic_zones()
    local found_prompt = false
    initial_text = get_zone_around_cursor(original_pane)

    wezterm.log_error("initial_text>>")
    wezterm.log_error(initial_text)

    -- Write initial text to temp file
    write_file(temp_file_path, initial_text)

    -- 2. Spawn a new window running neovim
    -- Use zsh -lic to ensure user config/path is loaded for nvim
    local _, new_pane, _ = mux.spawn_window({
        args = {"/bin/zsh", "-lic", "nvim " .. temp_file_path}
    })
    local new_pane_id = new_pane:pane_id()

    -- 3. Poll for the editor pane to close
    set_interval(0.5, function()
        local ok, _ = pcall(mux.get_pane, new_pane_id)
        if not ok then
            -- The new pane is dead (editor exited)
            local content = read_file(temp_file_path)
            if content then
                -- Trim the trailing newline that editors typically add
                content = content:gsub("[\n\r]+$", "")

                -- Send the edited text back to the original pane
                local p_ok, live_orig = pcall(mux.get_pane, original_pane_id)
                if p_ok and live_orig then
                    -- Clear the current line and paste the new content
                    -- \x01 (Ctrl-A) moves to start of line
                    -- \x15 (Ctrl-U) clears to start of line (bash/zsh)
                    -- \x0b (Ctrl-K) clears to end of line
                    -- sending Ctrl-U and Ctrl-K is safer to clear the whole line
                    live_orig:send_text("\x15\x0b" .. content)
                end
            end

            -- Cleanup
            os.remove(temp_file_path)
            return false -- Stop polling
        end
        return true -- Continue polling
    end)
end

local function open_yazi(window, pane)
    local cwd = pane_cwd_path(pane)
    local _, _, new_window = mux.spawn_window({
        cwd = cwd,
        args = {'/opt/homebrew/bin/yazi'}
    })
    local gui_window = new_window:gui_window()
    if gui_window then
        set_window_override(gui_window, "enable_tab_bar", false)
    end
end

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
        fuzzy = false,
        fuzzy_description = 'Search: '
        -- 增加一些样式配置 (WezTerm Nightly 支持)
        -- alphabetical = false,
    }, pane)
end

local key_binding = {
    key = 'e',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
        M.activate(window, pane)
    end)
}

function M.setup(config)
    wezterm.log_error("temp_edit plugin setup")
    -- 确保 config.keys 表存在
    config.keys = config.keys or {}

    -- 注意：这里我们需要把 key binding 改为调用 action_callback 以便动态执行 M.activate

    table.insert(config.keys, {
        key = "N",
        mods = "CMD|SHIFT",
        -- action = wezterm.action_callback(trigger_edit)
        action = wezterm.action_callback(trigger_nvim_edit)
    })
    table.insert(config.keys, {
        key = "e",
        mods = "CMD",
        action = wezterm.action_callback(trigger_cmd_edit)
    })
    -- table.insert(config.keys, key_binding)
    table.insert(config.keys, {
        key = "O",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(open_yazi)
    })

end

return M
