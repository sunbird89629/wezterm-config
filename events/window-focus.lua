local wezterm = require("wezterm")

local M = {}

local FOCUSED_OPACITY = 0.9
local UNFOCUSED_OPACITY = 0.8

local FOCUSED_BORDER = "#C06DD8"
local UNFOCUSED_BORDER = "#2a324a"

local function build_window_frame(frame, color)
    local border_width = frame.border_left_width or "2px"
    return {
        border_left_width = frame.border_left_width or border_width,
        border_right_width = frame.border_right_width or border_width,
        border_top_height = frame.border_top_height or border_width,
        border_bottom_height = frame.border_bottom_height or border_width,
        border_left_color = color,
        border_right_color = color,
        border_top_color = color,
        border_bottom_color = color
    }
end

local function apply_focus_style(window, focused)
    local overrides = window:get_config_overrides() or {}
    local effective = window:effective_config()
    local frame = effective.window_frame or {}
    -- local target_opacity = focused and FOCUSED_OPACITY or UNFOCUSED_OPACITY
    local target_color = focused and FOCUSED_BORDER or UNFOCUSED_BORDER
    local target_frame = build_window_frame(frame, target_color)

    local current_frame = overrides.window_frame or {}
    local needs_update = overrides.window_background_opacity ~= target_opacity or current_frame.border_left_color ~=
                             target_frame.border_left_color or current_frame.border_right_color ~=
                             target_frame.border_right_color or current_frame.border_top_color ~=
                             target_frame.border_top_color or current_frame.border_bottom_color ~=
                             target_frame.border_bottom_color

    if not needs_update then
        return
    end

    overrides.window_background_opacity = target_opacity
    overrides.window_frame = target_frame
    window:set_config_overrides(overrides)
end

function M.setup()
    wezterm.on("window-focus-changed", function(window, _pane)
        apply_focus_style(window, window:is_focused())
    end)
end

return M
