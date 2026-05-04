local wezterm = require("wezterm")
local time = wezterm.time
local act = wezterm.action
local mux = wezterm.mux
local io = require("io")
local os = require("os")

local M = {}

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

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

local function get_pane_cwd(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then
        return nil
    end

    -- New version might be a Url object
    if type(cwd) == 'userdata' or type(cwd) == 'table' then
        return cwd.file_path
    end

    -- Old version is URI string
    if type(cwd) == 'string' and wezterm.url and wezterm.url.parse then
        local ok, url = pcall(wezterm.url.parse, cwd)
        if ok and url and url.file_path then
            return url.file_path
        end
    end

    -- Fallback: strip file:// prefix
    if type(cwd) == 'string' then
        return (cwd:gsub('^file://[^/]*', ''))
    end

    return nil
end

local function get_active_screen()
    local screens = wezterm.gui.screens()
    return screens.active or screens.main
end

local function apply_dialog_styling(gui_window)
    if not gui_window then
        return
    end
    set_window_override(gui_window, "enable_tab_bar", false)

    local screen = get_active_screen()
    local target_w = math.floor(screen.width * 0.86)
    local target_h = math.floor(screen.height * 0.86)
    gui_window:set_inner_size(target_w, target_h)
end

local function write_file(path, content)
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
    else
        wezterm.log_error("Failed to write to " .. path)
    end
end

local function read_file(path)
    local f = io.open(path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        return content
    end
    return nil
end

local function get_text_around_cursor(pane)
    local cursor = pane:get_cursor_position()
    -- using x-1 here because the cursor may be one cell outside the zone
    local zone = pane:get_semantic_zone_at(cursor.x - 1, cursor.y)
    if zone then
        return pane:get_text_from_semantic_zone(zone)
    end
    return nil
end

--------------------------------------------------------------------------------
-- Action Handlers
--------------------------------------------------------------------------------

local TEMP_NVIM_FILE = "/tmp/wezterm_temp_file.txt"

-- Read temp file and push its content to clipboard, then clean up.
local function handle_pane_exit(window, pane)
    wezterm.run_child_process({"/bin/sh", "-c", "/usr/bin/pbcopy < " .. TEMP_NVIM_FILE})
    if window and pane then
        pcall(function()
            window:perform_action(act.CloseCurrentTab({
                confirm = false
            }), pane)
        end)
    end
end

local function trigger_nvim_edit()
    local lib = wezterm.plugin.require("https://github.com/chrisgve/lib.wezterm")
    lib.file_io.write_file(TEMP_NVIM_FILE, "")
    local _, pane, window = mux.spawn_window({
        args = {"/bin/zsh", "-lic", "nvim " .. TEMP_NVIM_FILE}
    })

    local gui_window = window:gui_window()
    apply_dialog_styling(gui_window)

    local pane_id = pane:pane_id()
    set_interval(0.2, function()
        local ok, live_pane = pcall(mux.get_pane, pane_id)
        if ok and live_pane then
            return true
        else
            handle_pane_exit(window, pane)
            return false
        end
    end)
end

local function trigger_gemini_edit()
    wezterm.run_child_process({"/usr/local/bin/code", "/Users/hao/.gemini"})
end

local function trigger_cmd_edit(window, pane)
    local original_pane_id = pane:pane_id()
    local temp_path = "/tmp/wezterm_edit_" .. tostring(original_pane_id) .. "_" .. os.time() .. ".txt"

    local initial_text = get_text_around_cursor(pane) or ""
    write_file(temp_path, initial_text)

    local _, new_pane = mux.spawn_window({
        args = {"/bin/zsh", "-lic", "nvim " .. temp_path}
    })
    local new_pane_id = new_pane:pane_id()

    set_interval(0.5, function()
        local ok = pcall(mux.get_pane, new_pane_id)
        if not ok then
            local content = read_file(temp_path)
            if content then
                content = content:gsub("[\n\r]+$", "")
                local p_ok, live_orig = pcall(mux.get_pane, original_pane_id)
                if p_ok and live_orig then
                    live_orig:send_text("\x15\x0b" .. content)
                end
            end
            os.remove(temp_path)
            return false
        end
        return true
    end)
end

local function open_yazi(window, pane)
    local cwd = get_pane_cwd(pane)
    local _, _, new_window = mux.spawn_window({
        cwd = cwd,
        args = {'/opt/homebrew/bin/yazi'}
    })
    local gui_win = new_window:gui_window()
    gui_win:set_config_overrides({
        colors = {
            background = '#1a1145',
        },
    })
end

--------------------------------------------------------------------------------
-- UI Builders
--------------------------------------------------------------------------------

local PALETTE_COMMANDS = {{
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

local function build_palette_label(cmd, width)
    local fixed_len = 4 + #cmd.label + 2 + #cmd.desc + 2 + #cmd.key
    local padding = math.max(0, width - fixed_len)

    return wezterm.format({{
        Foreground = {
            AnsiColor = cmd.color
        }
    }, {
        Text = cmd.icon .. '   '
    }, 'ResetAttributes', {
        Attribute = {
            Intensity = 'Bold'
        }
    }, {
        Text = cmd.label
    }, {
        Attribute = {
            Intensity = 'Normal'
        }
    }, {
        Text = '  '
    }, {
        Foreground = {
            AnsiColor = 'Grey'
        }
    }, {
        Attribute = {
            Intensity = 'Half'
        }
    }, {
        Text = cmd.desc
    }, {
        Attribute = {
            Intensity = 'Normal'
        }
    }, {
        Text = string.rep(' ', padding)
    }, {
        Foreground = {
            AnsiColor = 'Yellow'
        }
    }, {
        Text = cmd.key ~= 'None' and cmd.key or ''
    }})
end

function M.activate_palette(window, pane)
    local choices = {}
    for _, cmd in ipairs(PALETTE_COMMANDS) do
        table.insert(choices, {
            id = cmd.id,
            label = build_palette_label(cmd, 80)
        })
    end

    window:perform_action(act.InputSelector {
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
        action = wezterm.action_callback(function(win, p, id, label)
            if not id then
                return
            end
            if id == 'reload' then
                win:perform_action(act.ReloadConfiguration, p)
            elseif id == 'debug' then
                win:perform_action(act.ShowDebugOverlay, p)
            elseif id == 'split_h' then
                win:perform_action(act.SplitHorizontal {
                    domain = 'CurrentPaneDomain'
                }, p)
            elseif id == 'split_v' then
                win:perform_action(act.SplitVertical {
                    domain = 'CurrentPaneDomain'
                }, p)
            elseif id == 'zoom' then
                win:perform_action(act.TogglePaneZoomState, p)
            elseif id == 'theme' then
                win:perform_action(act.InputSelector {
                    title = 'Select Theme',
                    choices = wezterm.get_builtin_color_schemes(),
                    fuzzy = true,
                    action = wezterm.action_callback(function(w, _, theme_id)
                        if theme_id then
                            w:set_config_overrides({
                                color_scheme = theme_id
                            })
                        end
                    end)
                }, p)
            else
                win:toast_notification('Demo', 'Selected: ' .. label, nil, 2000)
            end
        end)
    }, pane)
end

local QUICK_EDIT_BINDING = {
    key = 'e',
    mods = 'CMD',
    action = act.InputSelector {
        title = 'Quick Edit',
        choices = {{
            label = "Current Command Edit With Neovim",
            id = 'edit_current_command'
        }, {
            label = "Edit With Neovim",
            id = 'edit_with_neovim'
        }, {
            label = 'Edit Gemini Config',
            id = 'edit_gemini_config'
        }},
        action = wezterm.action_callback(function(window, pane, id)
            if id == 'edit_current_command' then
                trigger_cmd_edit(window, pane)
            elseif id == 'edit_with_neovim' then
                trigger_nvim_edit()
            elseif id == 'edit_gemini_config' then
                trigger_gemini_edit()
            end
        end)
    }
}

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function M.setup(config)
    config.keys = config.keys or {}

    -- Command+Shift+N: Trigger simple nvim edit
    table.insert(config.keys, {
        key = "N",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(trigger_nvim_edit)
    })

    -- Command+E: Quick Edit Selector
    table.insert(config.keys, QUICK_EDIT_BINDING)

    -- Command+Shift+O: Open Yazi
    table.insert(config.keys, {
        key = "O",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(open_yazi)
    })
end

return M
