local wezterm = require("wezterm") ---@type Wezterm
local act = wezterm.action
local config = wezterm.config_builder() ---@type Config
config.debug_key_events = false
config.initial_rows = 25
config.initial_cols = 98
config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400
-- 基础样式配置
require("config.appearance").setup(config)
-- 快捷键配置
require("config.bindings").setup(config)
-- SSH domains
require("config.domains").setup(config)
-- Plugins
require("config.plugins.bar").setup(config)
require("config.plugins.quick_domains").setup(config)
-- require("config.plugins.modal").setup(config)

-- 继承官方默认 key_tables（关键：否则你自己写 copy_mode 会覆盖默认）
config.key_tables = wezterm.gui.default_key_tables()

-- Esc 退出 copy mode（顺便清掉选区，避免残留高亮）
table.insert(config.key_tables.copy_mode, {
    key = 'Escape',
    mods = 'NONE',
    action = act.Multiple {act.CopyMode 'Close', act.ClearSelection}
})

return config

-- =========== Command Palette 扩展 ===========
-- wezterm.on("augment-command-palette", function(window, pane)
--     return {{
--         brief = "Rename tab",
--         icon = "md_rename_box",
--         action = act.PromptInputLine({
--             description = "Enter new name for tab",
--             initial_value = "My Tab Name",
--             action = wezterm.action_callback(function(window, pane, line)
--                 if line then
--                     window:active_tab():set_title(line)
--                 end
--             end)
--         })
--     }}
-- end)
