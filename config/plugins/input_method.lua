local wezterm = require('wezterm')
local act = wezterm.action
local Logger = require('config.utils.logger')
local switch_to_english = require('config.utils.input-method').switch_to_english

local M = {}

local _initialized = false

local MAX_SEEN = 50

local DEFAULTS = {
   event = 'window-focus-changed',
}

local function resolve_opts(opts)
   opts = opts or {}
   return {
      event = opts.event or DEFAULTS.event,
      verbose = opts.verbose or false,
   }
end

function M.setup(config, opts)
   if _initialized then return end
   _initialized = true
   local resolved = resolve_opts(opts)
   local log = Logger.new('input_method', resolved.verbose)
   local seen_windows = {}
   local seen_count = 0

   wezterm.on(resolved.event, function(window, _pane)
      if not window:is_focused() then
         return
      end
      local mux_window = window:mux_window()
      if not mux_window then
         return
      end
      local id = mux_window:window_id()
      if seen_windows[id] then
         return
      end
      if seen_count >= MAX_SEEN then
         -- Simple cap: accept one re-trigger per window after reset.
         seen_windows = {}
         seen_count = 0
         log.info('seen_windows reset')
      end
      seen_windows[id] = true
      seen_count = seen_count + 1
      switch_to_english(log)
   end)

   table.insert(config.keys, {
      key = 't',
      mods = 'CMD',
      action = wezterm.action_callback(function(window, pane)
         switch_to_english(log)
         window:perform_action(act.SpawnTab('CurrentPaneDomain'), pane)
      end),
   })
   table.insert(config.keys, {
      key = 'P',
      mods = 'CMD|SHIFT',
      action = wezterm.action_callback(function(window, pane)
         switch_to_english(log)
         window:perform_action(act.ActivateCommandPalette, pane)
      end),
   })
   table.insert(config.keys, {
      key = 'F3',
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
         switch_to_english(log)
         window:perform_action(act.ShowLauncher, pane)
      end),
   })
   table.insert(config.keys, {
      key = 'F4',
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
         switch_to_english(log)
         window:perform_action(act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }), pane)
      end),
   })
   table.insert(config.keys, {
      key = 'F5',
      mods = 'NONE',
      action = wezterm.action_callback(function(window, pane)
         switch_to_english(log)
         window:perform_action(act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }), pane)
      end),
   })
   table.insert(config.keys, {
      key = 's',
      mods = 'CMD',
      action = wezterm.action_callback(function(window, pane)
         switch_to_english(log)
         window:perform_action(act.PaneSelect, pane)
      end),
   })
end

return M
