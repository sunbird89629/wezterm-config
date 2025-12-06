local wezterm = require("wezterm")
local quick_domains = wezterm.plugin.require("https://github.com/DavidRR-F/quick_domains.wezterm")

local M = {}

-- 自定义 fuzzy selector 行显示样式
local function formatter(icon, name, label)
  local text = icon .. " " .. string.lower(name)

  if label and #label > 0 then
    text = text .. " — " .. label
  end

  return wezterm.format({
    { Attribute = { Intensity = "Bold" } },
    { Text = text },
  })
end

function M.setup(config)
  quick_domains.formatter = formatter
  quick_domains.apply_to_config(config, {
    keys = {
      attach = {
        mods = "CMD|SHIFT",
        key = "d",
        tbl = "",
      },
      -- vsplit = { mods = "CTRL|SHIFT", key = "v", tbl = "" },
      -- hsplit = { mods = "CTRL|SHIFT", key = "h", tbl = "" },
    },
    -- icons / auto / docker_shell 等保持默认，后续需要再加
  })
end

return M
