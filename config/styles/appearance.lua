local M = {}

function M.setup(config)
    config.window_background_opacity = 0.9
    config.macos_window_background_blur = 40
    config.window_close_confirmation = "NeverPrompt"
    config.default_cursor_style = "BlinkingBar"
    config.color_scheme = 'Abernathy'
    config.inactive_pane_hsb = {
        saturation = 0.4,
        brightness = 0.4
    }

    config.colors = config.colors or {}
    config.colors.split = "#FF4444"

    config.window_padding = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
end

return M
