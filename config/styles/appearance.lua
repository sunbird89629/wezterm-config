local M = {}

function M.setup(config)
    config.window_close_confirmation = "NeverPrompt"
    config.default_cursor_style = "BlinkingBar"
    config.color_scheme = 'Abernathy'
    config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"

    config.window_padding = {
        left = 30,
        right = 30,
        top = 30,
        bottom = 30
    }
end

return M
