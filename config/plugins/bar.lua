local wezterm = require("wezterm")
local M = {}

function M.setup(config)
  local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
  bar.apply_to_config(config)
end

return M
