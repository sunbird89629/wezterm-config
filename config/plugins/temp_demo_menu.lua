local wezterm = require("wezterm")
local M = {}

function M.setup(config)
  -- 确保 config.keys 表存在
  config.keys = config.keys or {}

  table.insert(config.keys, {
    key = "e",
    mods = "CMD|SHIFT",
    action = wezterm.action.InputSelector({
      title = "Demo Selection Box",
      choices = {
        { label = "Option 1 (opt1)", id = "opt1" },
        { label = "Option 2 (opt2)", id = "opt2" },
        { label = "Hello World (hello)", id = "hello" },
      },
      action = wezterm.action_callback(function(window, pane, id, label)
        if not id and not label then
          wezterm.log_info("Demo Menu: User cancelled")
        else
          wezterm.log_info("Demo Menu: User selected " .. label .. " (id: " .. id .. ")")
          window:toast_notification("Selection", "You chose: " .. label, nil, 4000)
        end
      end),
    }),
  })
end

return M
