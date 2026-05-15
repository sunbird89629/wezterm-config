# Input Method Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Separate the dual-role `config/events/input-method.lua` into a pure utility module (`utils/input-method.lua`) and a focused event handler, then fix the missing input-method switch in lazygit.

**Architecture:** Extract `switch_to_english()` into a new `utils/input-method.lua` module. Both the event handler and plugins depend on this utility. Zero changes to `wezterm.lua`.

**Tech Stack:** Lua (WezTerm config), `im-select` (macOS input method switcher)

---

### Task 1: Create `config/utils/input-method.lua`

**Files:**
- Create: `config/utils/input-method.lua`

- [ ] **Step 1: Create the new utility module**

```lua
local wezterm = require("wezterm")

local M = {}

local ENGLISH_INPUT_ID = "com.apple.keylayout.ABC"

function M.switch_to_english()
    local candidates = {}
    local env_path = os.getenv("IM_SELECT")
    if env_path and env_path ~= "" then
        table.insert(candidates, env_path)
    end
    table.insert(candidates, "/opt/homebrew/bin/im-select")
    table.insert(candidates, "/usr/local/bin/im-select")
    table.insert(candidates, "im-select")

    for _, im_select in ipairs(candidates) do
        local ok, success, _, stderr = pcall(wezterm.run_child_process, {im_select, ENGLISH_INPUT_ID})
        if ok and success then
            return
        end
        if ok and stderr and stderr ~= "" then
            wezterm.log_error("im-select error: " .. stderr)
        end
    end

    wezterm.log_error("Failed to switch input method; set IM_SELECT or fix PATH.")
end

return M
```

- [ ] **Step 2: Commit**

```bash
git add config/utils/input-method.lua
git commit -m "feat: extract input-method utility module

Move switch_to_english() from config/events/input-method.lua into a new
pure utility module at config/utils/input-method.lua. No functional changes.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: Simplify `config/events/input-method.lua`

**Files:**
- Modify: `config/events/input-method.lua`

- [ ] **Step 1: Replace the file to delegate to utils**

Replace the entire file content with:

```lua
local wezterm = require("wezterm")
local im = require("config.utils.input-method")

local M = {}

function M.setup()
    local seen_windows = {}
    wezterm.on("window-focus-changed", function(window, _pane)
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

        seen_windows[id] = true
        im.switch_to_english()
    end)
end

return M
```

- [ ] **Step 2: Commit**

```bash
git add config/events/input-method.lua
git commit -m "refactor: delegate input-method events to utils module

Remove set_english_input() and ENGLISH_INPUT_ID from the event handler.
window-focus-changed now calls utils.input-method.switch_to_english().

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: Update yazi and lazygit plugins

**Files:**
- Modify: `config/plugins/yazi.lua:47`
- Modify: `config/plugins/lazygit.lua:41-43`

- [ ] **Step 1: Update yazi require path**

In `config/plugins/yazi.lua`, change line 47 from:
```lua
        require("config.events.input-method").set_english_input()
```
to:
```lua
        require("config.utils.input-method").switch_to_english()
```

- [ ] **Step 2: Add input method switch to lazygit**

In `config/plugins/lazygit.lua`, in `make_open_fn`, add `require("config.utils.input-method").switch_to_english()` before `SpawnCommandInNewTab`:

```lua
local function make_open_fn(opts)
    return function(window, pane)
        require("config.utils.input-method").switch_to_english()
        local cwd = get_pane_cwd(pane)
        window:perform_action(act.SpawnCommandInNewTab {
            cwd  = cwd,
            args = { opts.binary },
            set_environment_variables = { PATH = build_path(opts.extra_paths) },
        }, pane)
    end
end
```

- [ ] **Step 3: Commit**

```bash
git add config/plugins/yazi.lua config/plugins/lazygit.lua
git commit -m "refactor: update plugins to use utils.input-method

- yazi: update require path from config.events.input-method to utils.input-method
- lazygit: add switch_to_english() before spawn, fixing missing input method switch

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```
