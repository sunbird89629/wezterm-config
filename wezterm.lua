local wezterm = require("wezterm") ---@type Wezterm
local act = wezterm.action
local config = wezterm.config_builder() ---@type Config
config.debug_key_events = false
config.initial_rows = 45
config.initial_cols = 160
config.check_for_updates = false
config.check_for_updates_interval_seconds = 86400

local base_path = os.getenv("PATH") or ""
local extra_path = "/opt/homebrew/bin"
local merged_path = base_path
if not base_path:find(extra_path, 1, true) then
    merged_path = base_path .. ":" .. extra_path
end
config.set_environment_variables = {
    PATH = merged_path
}

-- 基础样式配置
require("config.appearance").setup(config)
-- Window focus styling
require("events.window-focus").setup()
-- Set input method when a new window is first focused
require("events.input-method").setup()
-- 快捷键配置
require("config.bindings").setup(config)
-- SSH domains
require("config.domains").setup(config)
-- Plugins
-- require("config.plugins.bar").setup(config)
require("config.plugins.tabline").setup(config)
require("config.plugins.replay").setup(config)
require("config.plugins.toggle_terminal").setup(config)
require("config.plugins.quick_domains").setup(config)
require("config.plugins.ai_helper").setup(config)
require("config.plugins.temp_edit").setup(config)
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
