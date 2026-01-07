local wezterm = require("wezterm")
local ai_helper = wezterm.plugin.require("https://github.com/Michal1993r/ai-helper.wezterm")

local M = {}

function M.setup(config)
  ai_helper.apply_to_config(config, {
    type = "google",
    api_key = "AIzaSyBFTCS6K5OmlJAGkWxgFr1vF6JDfeKFwkU",
    model = "google/gemma-3-4b",
    luarocks_path = "/opt/homebrew/bin/luarocks",
  })
end

return M
