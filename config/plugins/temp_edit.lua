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

-- Copy text to clipboard via GUI window if available; fallback to pbcopy.
-- local function copy_file_to_clipboard(window, text)
--     local gui_window = nil
--     if window and window.gui_window then
--         local ok, gw = pcall(function()
--             return window:gui_window()
--         end)
--         if ok then
--             gui_window = gw
--         end
--     end

--     if gui_window then
--         gui_window:copy_to_clipboard(text)
--         return true
--     end

--     local ok, _, stderr = wezterm.run_child_process({"/bin/sh", "-c", "/usr/bin/pbcopy < " .. tmp_file_path})
--     if not ok then
--         wezterm.log_error("Failed to copy to clipboard via pbcopy: " .. (stderr or ""))
--     end
--     return ok
-- end

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
    wezterm.log_error("################### trigger_nvim_edit ##################")
    lib.file_io.write_file(temp_file_name, "")
    local _, pane, window = mux.spawn_window({
        args = {"/bin/zsh", "-lic", "nvim " .. temp_file_name}
    })

    local pane_id = pane:pane_id()

    set_interval(0.2, function()
        -- wezterm.log_error("pane check running.....")
        local ok, live_pane = pcall(mux.get_pane, pane_id)
        if ok and live_pane then
            return true
        else
            on_pane_exit(window, pane)
            return false
        end
    end)
    wezterm.log_error("###################################################")
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
    -- if zones then
    --     for index, zone in ipairs(zones) do
    --         wezterm.log_error("zones.index>>>>>>>>>>>>>>>>>" .. index)
    --         wezterm.log_error(wezterm.to_string(zone))
    --         wezterm.log_error(original_pane:get_text_from_semantic_zone(zone))
    --         -- original_pane:get_text_from_region()
    --     end
    -- end

    -- wezterm.log_error("cursor>>")
    -- log_table_for_debug(cursor)
    -- wezterm.log_error("zones>>")
    -- wezterm.log_error(wezterm.to_string(zones))

    local found_prompt = false
    -- if zones then
    --     -- for i = #zones, 1, -1 do
    --     -- Find the last prompt that is at or above the cursor
    --     -- if zones[i].semantic_type == "Prompt" and zones[i].start_y <= cursor.y then
    --     --     local prompt_end_y = zones[i].end_y
    --     --     local prompt_end_x = zones[i].end_x

    --     --     -- Safety check: prevent capturing excessive amount of text which might cause crashes
    --     --     if (cursor.y - prompt_end_y) > 1000 then
    --     --         wezterm.log_warn("Prompt too far back, limiting capture to last 1000 lines to prevent crash")
    --     --         prompt_end_y = cursor.y - 1000
    --     --         prompt_end_x = 0
    --     --     end

    --     --     -- Capture text from the end of the prompt to a reasonable limit (cursor row + 10)
    --     --     initial_text = original_pane:get_text_from_region(prompt_end_y, prompt_end_x, cursor.y + 10, 0)
    --     --     found_prompt = true
    --     --     break
    --     -- end
    --     -- wezterm.log_error("zones:" .. i)
    --     -- wezterm.log_error(wezterm.to_string(zones[i]))
    --     -- end
    -- end

    -- if not found_prompt then
    --     -- Fallback: Get text of the current line
    --     initial_text = original_pane:get_lines_as_text(1)
    --     -- Simple heuristic to strip common prompts if possible, or just take the line
    --     -- initial_text = initial_text:gsub("^.*[$%%>]%s*", "")
    -- end

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
end

return M
