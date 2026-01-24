local wezterm = require("wezterm")
local ai_helper = wezterm.plugin.require("https://github.com/Michal1993r/ai-helper.wezterm")

local M = {}

function M.setup(config)
  -- Try to load secrets, fail gracefully if not found
  local secrets_ok, secrets = pcall(require, "secrets")
  local google_api_key = ""
  
  if secrets_ok and secrets.google_api_key then
    google_api_key = secrets.google_api_key
  else
    -- Fallback to environment variable
    google_api_key = os.getenv("GOOGLE_API_KEY") or ""
  end

  ai_helper.apply_to_config(config, {
    type = "google",
    api_key = google_api_key,
    model = "google/gemma-3-4b",
    luarocks_path = "/opt/homebrew/bin/luarocks",
  })
end

return M
