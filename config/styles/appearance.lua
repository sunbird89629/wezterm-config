local M = {}

function M.setup(config)
    config.window_close_confirmation = "NeverPrompt"
    config.default_cursor_style = "BlinkingBar"
    config.color_scheme = 'Abernathy'
    config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"
    config.inactive_pane_hsb = {
        saturation = 0.4, -- 饱和度倍数（1.0 = 不变）
        brightness = 0.4 -- 亮度倍数（越小越暗）
    }
    config.colors.split = "#FF4444"

    config.window_padding = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
end

return M
