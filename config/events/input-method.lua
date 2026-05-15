local wezterm = require("wezterm")
local im = require("config.utils.input-method")

local M = {}

local MAX_SEEN = 50

function M.setup()
    local seen_windows = {}
    local seen_count = 0
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

        if seen_count >= MAX_SEEN then
            seen_windows = {}
            seen_count = 0
        end

        seen_windows[id] = true
        seen_count = seen_count + 1
        im.switch_to_english()
    end)
end

return M
