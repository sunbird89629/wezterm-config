local wezterm = require("wezterm")

local M = {}

local ENGLISH_INPUT_ID = "com.apple.keylayout.ABC"

local function resolve_im_select()
    local env_path = os.getenv("IM_SELECT")
    local candidates = {}
    if env_path and env_path ~= "" then
        table.insert(candidates, env_path)
    end
    table.insert(candidates, "/opt/homebrew/bin/im-select")
    table.insert(candidates, "/usr/local/bin/im-select")
    table.insert(candidates, "im-select")

    local debug_candidates = {}
    for _, candidate in ipairs(candidates) do
        table.insert(debug_candidates, candidate)
    end
    wezterm.log_info("im-select candidates: " .. table.concat(debug_candidates, ", "))

    for _, candidate in ipairs(candidates) do
        if candidate and candidate ~= "" then
            if candidate:sub(1, 1) == "/" then
                wezterm.log_info("im-select using absolute path: " .. candidate)
                return candidate
            else
                local ok, _, _ = wezterm.run_child_process({"/usr/bin/which", candidate})
                if ok then
                    wezterm.log_info("im-select resolved via PATH: " .. candidate)
                    return candidate
                end
            end
        end
    end

    return nil
end

local function set_english_input()
    local im_select = resolve_im_select()
    if not im_select then
        wezterm.log_error("im-select not found; set IM_SELECT or add it to PATH.")
        return
    end

    local ok, _, stderr = wezterm.run_child_process({im_select, ENGLISH_INPUT_ID})
    if not ok then
        wezterm.log_error("Failed to switch input method: " .. (stderr or ""))
    end
end

function M.setup()
    local seen_windows = {}
    wezterm.on("window-focus-changed", function(window, _pane)
        if not window:is_focused() then
            return
        end

        local mux_window = window:mux_window()
        if not mux_window then
            return
        end

        local id = mux_window:window_id()
        if seen_windows[id] then
            return
        end

        seen_windows[id] = true
        set_english_input()
    end)
end

return M
