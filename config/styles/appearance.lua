local M = {}

function M.setup(config)
    config.window_close_confirmation = "NeverPrompt"
    config.default_cursor_style = "BlinkingBar"
    config.color_scheme = 'Abernathy'
    config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"

    config.window_padding = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
end

return M
