local wezterm = require("wezterm") ---@type Wezterm
local M = {}

function M.setup(config)
    -- =========== 基础外观 ===========
    config.window_background_opacity = 0.9
    config.window_close_confirmation = "NeverPrompt"
    config.macos_window_background_blur = 40
    config.default_cursor_style = "BlinkingBar"
    config.font_size = 24
    -- config.color_scheme = "Nord (Gogh)"
    config.color_scheme = "Glacier"
   --  config.colors={
   --    tab_bar = {
   --    active_tab = {
   --      bg_color = "#26233a"
   --    }
   --  }
   --  }

    config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"

   --  config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }
    local border_width = "2px";
    local border_color = "#C06DD8";
    config.window_frame = {
        border_left_width = border_width,
        border_right_width =border_width,
        border_top_height = border_width,
        border_bottom_height = border_width,
        border_left_color = border_color,
        border_right_color = border_color,
        border_top_color = border_color,
        border_bottom_color = border_color
    }

    -- =========== Command Palette 外观 ===========
    config.command_palette_font = wezterm.font("JetBrains Mono")
    config.command_palette_font_size = 28.0


    config_tab_bar_colors(config)
end

function config_tab_bar_colors(config)
  -- config.colors = {
--   tab_bar = {
--     -- 整条 tabbar 的背景色（顶部那条“底板”）
--     background = "#0b0022",
--     active_tab = {
--       bg_color = "#2b2042",
--       fg_color = "#c0c0c0",
--     },
--     inactive_tab = {
--       bg_color = "#1b1032",
--       fg_color = "#808080",
--     },
--   },
-- }

-- config.use_fancy_tab_bar = false
config.colors = {
  tab_bar = {
    background = "#0c0f1a", -- bar background
    active_tab = {
      bg_color = "#263859",
      fg_color = "#e8f1ff",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#121725",
      fg_color = "#8a94aa",
    },
    inactive_tab_hover = {
      bg_color = "#1a2135",
      fg_color = "#c5d7ff",
      italic = true,
    },
    new_tab = {
      bg_color = "#0c0f1a",
      fg_color = "#5d7cff",
    },
    new_tab_hover = {
      bg_color = "#1f2b45",
      fg_color = "#e8f1ff",
      italic = true,
    },
  },
}

-- -- Fancy tab bar（默认就是 true，这里写出来更直观）
-- config.use_fancy_tab_bar = true

-- config.window_frame = {
--   -- 窗口聚焦时 tabbar/标题区域背景
--   active_titlebar_bg = "#1e1e2e",
--   -- 窗口失焦时 tabbar/标题区域背景
--   inactive_titlebar_bg = "#181825",
-- }

-- -- 可选：设置 tabbar 边缘/分隔线颜色等
-- config.colors = {
--   tab_bar = {
--     inactive_tab_edge = "#313244",
--   },
-- }  
end

return M

-- local gpu_adapters = require('utils.gpu-adapter')
-- local backdrops = require('utils.backdrops')
-- local colors = require('colors.custom')

-- return {
--    max_fps = 120,
--    front_end = 'WebGpu', ---@type 'WebGpu' | 'OpenGL' | 'Software'
--    webgpu_power_preference = 'HighPerformance',
--    webgpu_preferred_adapter = gpu_adapters:pick_best(),
--    -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Dx12', 'IntegratedGpu'),
--    -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Gl', 'Other'),
--    underline_thickness = '1.5pt',

--    -- cursor
--    animation_fps = 120,
--    cursor_blink_ease_in = 'EaseOut',
--    cursor_blink_ease_out = 'EaseOut',
--    default_cursor_style = 'BlinkingBlock',
--    cursor_blink_rate = 650,

--    -- color scheme
--    colors = colors,

--    -- background: pass in `true` if you want wezterm to start with focus mode on (no bg images)
--    -- background = backdrops:initial_options(false),

--    -- scrollbar
--    enable_scroll_bar = true,

--    -- tab bar
--    enable_tab_bar = true,
--    hide_tab_bar_if_only_one_tab = false,
--    use_fancy_tab_bar = false,
--    tab_max_width = 25,
--    show_tab_index_in_tab_bar = false,
--    switch_to_last_active_tab_when_closing_tab = true,

--    -- command palette
--    command_palette_fg_color = '#b4befe',
--    command_palette_bg_color = '#11111b',
--    command_palette_font_size = 12,
--    command_palette_rows = 25,

--    -- window
--    window_padding = {
--       left = 8,
--       right = 8,
--       top = 8,
--       bottom = 8,
--    },
--    adjust_window_size_when_changing_font_size = false,
--    window_close_confirmation = 'NeverPrompt',
--    window_frame = {
--       active_titlebar_bg = '#090909',
--       -- font = fonts.font,
--       -- font_size = fonts.font_size,
--    },
--    -- inactive_pane_hsb = {
--    --    saturation = 0.9,
--    --    brightness = 0.65,
--    -- },
--    inactive_pane_hsb = {
--       saturation = 1,
--       brightness = 1,
--    },

--    visual_bell = {
--       fade_in_function = 'EaseIn',
--       fade_in_duration_ms = 250,
--       fade_out_function = 'EaseOut',
--       fade_out_duration_ms = 250,
--       target = 'CursorColor',
--    },
-- }
