local wezterm = require("wezterm") ---@type Wezterm
local act = wezterm.action
local config = wezterm.config_builder() ---@type Config
config.debug_key_events = false
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
