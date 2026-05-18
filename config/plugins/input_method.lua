local wezterm = require("wezterm")
local switch_to_english = require("config.utils.input-method").switch_to_english

local M = {}

local MAX_SEEN = 50

local DEFAULTS = {
    event = "window-focus-changed",
}

local function resolve_opts(opts)
    opts = opts or {}
    return {
        event = opts.event or DEFAULTS.event,
    }
end

function M.setup(config, opts)
    local resolved = resolve_opts(opts)
    local seen_windows = {}
    local seen_count = 0

    wezterm.on(resolved.event, function(window, _pane)
        if not window:is_focused() then return end
        local mux_window = window:mux_window()
        if not mux_window then return end
        local id = mux_window:window_id()
        if seen_windows[id] then return end
        if seen_count >= MAX_SEEN then
            seen_windows = {}
            seen_count = 0
        end
        seen_windows[id] = true
        seen_count = seen_count + 1
        switch_to_english()
    end)
end

return M
