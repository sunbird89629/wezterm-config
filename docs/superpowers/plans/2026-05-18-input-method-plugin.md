# input-method Plugin Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the input-method event handler from `config/events/input-method.lua` into a plugin at `config/plugins/input_method.lua`, matching the standard plugin convention.

**Architecture:** Create the plugin file that absorbs all event-wiring logic from the events file, then delete the events file and update the entry point. The shared utility (`config/utils/input-method.lua`) is untouched — lazygit and yazi continue to import from it.

**Tech Stack:** Lua (LuaJIT), WezTerm API

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `config/plugins/input_method.lua` | Plugin: registers `window-focus-changed` handler, calls util |
| Delete | `config/events/input-method.lua` | Replaced by plugin |
| Modify | `wezterm.lua` | Update require line |
| Unchanged | `config/utils/input-method.lua` | Pure utility, shared by lazygit/yazi/plugin |

---

### Task 1: Create the plugin file

**Files:**
- Create: `config/plugins/input_method.lua`

- [ ] **Step 1: Create the plugin**

Write `config/plugins/input_method.lua` with this exact content:

```lua
local wezterm = require("wezterm")
local switch_to_english = require("config.utils.input-method").switch_to_english

local M = {}

local MAX_SEEN = 50

local DEFAULTS = {
    event = "window-focus-changed",
}

local function resolve_opts(opts)
    opts = opts or {}
    return {
        event = opts.event or DEFAULTS.event,
    }
end

function M.setup(config, opts)
    local resolved = resolve_opts(opts)
    local seen_windows = {}
    local seen_count = 0

    wezterm.on(resolved.event, function(window, _pane)
        if not window:is_focused() then return end
        local mux_window = window:mux_window()
        if not mux_window then return end
        local id = mux_window:window_id()
        if seen_windows[id] then return end
        if seen_count >= MAX_SEEN then
            seen_windows = {}
            seen_count = 0
        end
        seen_windows[id] = true
        seen_count = seen_count + 1
        switch_to_english()
    end)
end

return M
```

- [ ] **Step 2: Lint check**

```bash
luacheck config/plugins/input_method.lua
```

Expected: no errors or warnings.

---

### Task 2: Update wezterm.lua

**Files:**
- Modify: `wezterm.lua`

- [ ] **Step 1: Replace the require line**

In `wezterm.lua`, find:

```lua
-- Set input method when a new window is first focused
require("config.events.input-method").setup()
```

Replace with:

```lua
-- Set input method when a new window is first focused
require("config.plugins.input_method").setup(config)
```

- [ ] **Step 2: Lint check**

```bash
luacheck wezterm.lua
```

Expected: no errors or warnings.

---

### Task 3: Delete the events file

**Files:**
- Delete: `config/events/input-method.lua`

- [ ] **Step 1: Delete the file**

```bash
git rm config/events/input-method.lua
```

Expected: `rm 'config/events/input-method.lua'`

---

### Task 4: Manual verification

- [ ] **Step 1: Reload WezTerm**

Open WezTerm (or reload config). Switch your macOS input method to a non-English source (e.g. Pinyin).

- [ ] **Step 2: Open a new window**

Open a new WezTerm window. The input method should automatically switch back to English (ABC).

- [ ] **Step 3: Verify second focus is a no-op**

Focus away from the window and focus back. Input method should NOT switch again (the `seen_windows` guard).

- [ ] **Step 4: Check WezTerm logs for errors**

Open the WezTerm debug overlay (`CMD+SHIFT+L` or `wezterm show-keys` to find your binding). Confirm no Lua errors related to `input_method` or `input-method`.

---

### Task 5: Commit

- [ ] **Step 1: Stage all changes**

```bash
git add config/plugins/input_method.lua wezterm.lua
```

(The `git rm` in Task 3 already staged the deletion.)

- [ ] **Step 2: Commit**

```bash
git commit -m "refactor(input-method): move event handler into plugin"
```
