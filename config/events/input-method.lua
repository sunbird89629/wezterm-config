local wezterm = require("wezterm")
local im = require("utils.input-method")

local M = {}

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
        im.switch_to_english()
    end)
end

return M
