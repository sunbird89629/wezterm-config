local wezterm = require("wezterm")
local M = {}

function M.setup(config)
  local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")
  modal.set_default_keys(config)
  wezterm.on("update-right-status", function(window, _)
    modal.set_right_status(window)
  end)
  modal.apply_to_config(config)
end

return M
