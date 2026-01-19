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

local function trigger_nvim_edit()
    lib.file_io.write_file(temp_file_name, "")
    local _, pane, window = mux.spawn_window({
        args = {"/bin/zsh", "-lic", "nvim " .. temp_file_name}
    })

    local gui_window = window:gui_window()
    set_window_override(gui_window, "enable_tab_bar", false)

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

function M.setup(config)
    wezterm.log_info("temp_edit plugin setup")
    if config.keys == nil then
        config.keys = {}
    end
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
    table.insert(config.keys, {
        key = "O",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(open_yazi)
    })

end

return M
