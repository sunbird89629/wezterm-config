# Plugin Logger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `Logger.new(name, enabled)` factory to `config/utils/logger.lua` and wire it into the `input_method` plugin so every log line carries a `[plugin_name]` prefix and can be silenced via `opts.verbose = false`.

**Architecture:** A single factory module returns no-op or live method tables depending on the `enabled` flag. The plugin creates a logger inside `setup()` and passes it down to utility functions. No global state.

**Tech Stack:** Lua 5.4 / LuaJIT, WezTerm built-in `wezterm.log_info` / `wezterm.log_error`. Lint: `luacheck .`. Format config: `.stylua.toml` (3-space indent, single quotes, 100-col).

---

## File Map

| Action | Path |
|--------|------|
| Create | `config/utils/logger.lua` |
| Modify | `config/utils/input-method.lua` |
| Modify | `config/plugins/input_method.lua` |

---

### Task 1: Create `config/utils/logger.lua`

**Files:**
- Create: `config/utils/logger.lua`

- [ ] **Step 1: Write the file**

```lua
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
```

- [ ] **Step 2: Lint**

```bash
luacheck config/utils/logger.lua
```

Expected: `0 warnings` (or only `wezterm` undefined-global warning, which is expected for WezTerm Lua — ignore it if `.luacheckrc` already suppresses it).

- [ ] **Step 3: Commit**

```bash
git add config/utils/logger.lua
git commit -m "feat(logger): add Logger factory utility"
```

---

### Task 2: Update `config/utils/input-method.lua`

**Files:**
- Modify: `config/utils/input-method.lua`

`switch_to_english()` currently calls `wezterm.log_info` / `wezterm.log_error` directly. Change its signature to accept a `log` parameter and delegate to it.

- [ ] **Step 1: Replace the file contents**

```lua
local wezterm = require('wezterm')

local M = {}

local ENGLISH_INPUT_ID = 'com.apple.keylayout.ABC'

function M.switch_to_english(log)
   local candidates = {}
   local env_path = os.getenv('IM_SELECT')
   if env_path and env_path ~= '' then
      table.insert(candidates, env_path)
   end
   table.insert(candidates, '/opt/homebrew/bin/im-select')
   table.insert(candidates, '/usr/local/bin/im-select')
   table.insert(candidates, 'im-select')

   for _, im_select in ipairs(candidates) do
      local ok, result = pcall(wezterm.run_child_process, { im_select, ENGLISH_INPUT_ID })
      if ok then
         return
      end
      log.info('im-select not found: ' .. tostring(result))
   end

   log.error('Failed to switch input method; set IM_SELECT or fix PATH.')
end

return M
```

- [ ] **Step 2: Lint**

```bash
luacheck config/utils/input-method.lua
```

Expected: `0 warnings`.

- [ ] **Step 3: Commit**

```bash
git add config/utils/input-method.lua
git commit -m "refactor(input-method): accept log parameter in switch_to_english"
```

---

### Task 3: Update `config/plugins/input_method.lua`

**Files:**
- Modify: `config/plugins/input_method.lua`

Create a logger inside `setup()` using `opts.verbose`, and pass it to every `switch_to_english()` call. Also expose `verbose` via `resolve_opts`.

- [ ] **Step 1: Replace the file contents**

```lua
local wezterm = require('wezterm')
local act = wezterm.action
local Logger = require('config.utils.logger')
local switch_to_english = require('config.utils.input-method').switch_to_english

local M = {}

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
```

- [ ] **Step 2: Lint the whole config**

```bash
luacheck .
```

Expected: same warning count as before this change (only pre-existing globals warnings).

- [ ] **Step 3: Manual smoke test — silent mode (default)**

In `wezterm.lua` the call is:
```lua
require("config.plugins.input_method").setup(config)
```
Reload WezTerm (`Ctrl+Shift+R`). Open the debug overlay (`Ctrl+Shift+L`). Switch focus between windows or open a new tab — no `[input_method]` lines should appear.

- [ ] **Step 4: Manual smoke test — verbose mode**

Temporarily change `wezterm.lua`:
```lua
require("config.plugins.input_method").setup(config, { verbose = true })
```
Reload WezTerm. Trigger a focus change or open a new tab. In the debug overlay you should see:
```
[input_method] im-select not found: ...   ← if path misses
-- or nothing if im-select succeeds (success path has no log line)
```
Revert `wezterm.lua` to remove `{ verbose = true }` after confirming.

- [ ] **Step 5: Commit**

```bash
git add config/plugins/input_method.lua
git commit -m "feat(input-method): wire Logger into plugin, verbose via opts"
```
