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

local function trigger_nvim_edit()
    wezterm.log_error("################### trigger_nvim_edit ##################")
    lib.file_io.write_file(temp_file_name, "")
    local _, pane, window = mux.spawn_window({
        args = {"/bin/zsh", "-lic", "nvim " .. temp_file_name}
    })

    local pane_id = pane:pane_id()

    -- Debugging: Print keys in lib to see what is available
    -- if lib then
    --     for k, v in pairs(lib) do
    --         wezterm.log_error("lib key: " .. k .. " -> " .. tostring(v))
    --         if type(v) == "table" then
    --             for k2, v2 in pairs(v) do
    --                 wezterm.log_error("  " .. k .. "." .. k2 .. " -> " .. tostring(v2))
    --             end
    --         end
    --     end
    -- end

    set_interval(0.2, function()
        wezterm.log_error("pane check running.....")
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
end

return M
