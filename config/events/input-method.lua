local wezterm = require("wezterm")

local M = {}

local ENGLISH_INPUT_ID = "com.apple.keylayout.ABC"

local function set_english_input()
    local candidates = {}
    local env_path = os.getenv("IM_SELECT")
    if env_path and env_path ~= "" then
        table.insert(candidates, env_path)
    end
    table.insert(candidates, "/opt/homebrew/bin/im-select")
    table.insert(candidates, "/usr/local/bin/im-select")
    table.insert(candidates, "im-select")

    for _, im_select in ipairs(candidates) do
        local ok, success, _, stderr = pcall(wezterm.run_child_process, {im_select, ENGLISH_INPUT_ID})
        if ok and success then
            return
        end
        if ok and stderr and stderr ~= "" then
            wezterm.log_error("im-select error: " .. stderr)
        end
    end

    wezterm.log_error("Failed to switch input method; set IM_SELECT or fix PATH.")
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
