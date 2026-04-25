local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    local quota = wezterm.plugin.require("https://github.com/EdenGibson/wezterm-quota-limit")
    quota.apply_to_config(config)
end

return M
