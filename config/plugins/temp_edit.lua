local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local time = wezterm.time

-- 该方法实现如下功能：
-- 1.创建一个临时文件
-- 2.打开一个新的 wezterm 窗口
-- 3.在新窗口中通过 vim 打开第一步创建的临时文件
-- 4.在 vim 中编辑完成，通过 :wq 退出 vim 的时候，把这个临时文件中的内容 copy 到系统剪切板

-- Track the temp file path across callbacks.
local tmp_file_path = nil

-- Copy text to clipboard via GUI window if available; fallback to pbcopy.
local function copy_file_to_clipboard(window, text)
    local gui_window = nil
    if window and window.gui_window then
        local ok, gw = pcall(function()
            return window:gui_window()
        end)
        if ok then
            gui_window = gw
        end
    end

    if gui_window then
        gui_window:copy_to_clipboard(text)
        return true
    end

    local ok, _, stderr = wezterm.run_child_process({
        "/bin/sh",
        "-c",
        "/usr/bin/pbcopy < " .. tmp_file_path
    })
    if not ok then
        wezterm.log_error("Failed to copy to clipboard via pbcopy: " .. (stderr or ""))
    end
    return ok
end

-- Read temp file and push its content to clipboard, then clean up.
local function on_vim_exit(window, pane)
    if not tmp_file_path then
        wezterm.log_error("Temporary file path not set; cannot copy content.")
        return
    end

    wezterm.log_info("Vim exited. Reading content from: " .. tmp_file_path)
    local file_content = ""
    local file = io.open(tmp_file_path, "r")
    if file then
        file_content = file:read("*all")
        file:close()
        -- Log only a short preview to avoid huge logs.
        wezterm.log_info("Content read: " .. file_content:sub(1, 100) .. "...")
        if copy_file_to_clipboard(window, file_content) then
            wezterm.log_info("Content copied to clipboard.")
        end
    else
        wezterm.log_error("Failed to read temporary file: " .. tmp_file_path)
    end

    -- Clean up the temporary file after copying.
    os.remove(tmp_file_path)
    wezterm.log_info("Temporary file removed: " .. tmp_file_path)

    -- Close the tab after vim exits and content is copied.
    if window and pane then
        pcall(function()
            window:perform_action(act.CloseCurrentTab({
                confirm = false
            }), pane)
        end)
    end
end

-- Resolve an editor command, preferring user env then fallback candidates.
local function resolve_editor()
    local env_editor = os.getenv("VISUAL") or os.getenv("EDITOR")
    local candidates = {}

    if env_editor and env_editor ~= "" then
        table.insert(candidates, env_editor)
    end

    table.insert(candidates, "nvim")
    table.insert(candidates, "vim")
    table.insert(candidates, "vi")

    local extra_paths = {"/opt/homebrew/bin/nvim"}

    for _, editor in ipairs(candidates) do
        local ok, _, _ = wezterm.run_child_process({"/usr/bin/which", editor})
        if ok then
            return editor
        end
    end

    for _, path in ipairs(extra_paths) do
        local ok, _, _ = wezterm.run_child_process({"/usr/bin/test", "-x", path})
        if ok then
            return path
        end
    end

    return nil
end

-- Spawn a new window, open the temp file, and wait for editor exit.
local function trigger_edit()
    local tmp_dir = os.getenv("TMPDIR") or "/tmp"
    if tmp_dir:sub(-1) ~= "/" then
        tmp_dir = tmp_dir .. "/"
    end
    tmp_file_path = tmp_dir .. "wezterm_tmp_edit.txt"
    wezterm.log_info("Creating temporary file: " .. tmp_file_path)
    local file = io.open(tmp_file_path, "w")
    if file then
        file:close()
    else
        wezterm.log_error("Failed to create temporary file: " .. tmp_file_path)
        return
    end

    local editor = resolve_editor()
    if not editor then
        wezterm.log_error("No editor found in PATH; set EDITOR/VISUAL or install nvim/vim.")
        return
    end

    -- Ensure Homebrew's default bin path is available to the editor.
    local base_path = os.getenv("PATH") or ""
    local extra_path = "/opt/homebrew/bin"
    local spawn_path = base_path
    if not base_path:find(extra_path, 1, true) then
        spawn_path = base_path .. ":" .. extra_path
    end

    wezterm.log_info("Spawning new window with editor for temporary edit.")
    local _, pane, window = mux.spawn_window({
        args = {editor, tmp_file_path},
        set_environment_variables = {
            PATH = spawn_path
        }
    })
    local pane_id = pane:pane_id()

    local function wait_for_pane_exit()
        local ok, live_pane = pcall(mux.get_pane, pane_id)
        if ok and live_pane then
            time.call_after(0.5, wait_for_pane_exit)
            return
        end
        on_vim_exit(window, pane)
    end

    time.call_after(0.5, wait_for_pane_exit)
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
        action = wezterm.action_callback(trigger_edit)
    })
end

return M
