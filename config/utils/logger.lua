local wezterm = require('wezterm')

local Logger = {}

function Logger.new(name, enabled)
   local prefix = '[' .. name .. '] '
   if not enabled then
      return { info = function() end, error = function() end }
   end
   return {
      info = function(msg) wezterm.log_info(prefix .. tostring(msg)) end,
      error = function(msg) wezterm.log_error(prefix .. tostring(msg)) end,
   }
end

return Logger
