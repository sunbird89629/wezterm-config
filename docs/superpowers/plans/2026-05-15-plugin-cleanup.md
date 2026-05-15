# Plugin Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate duplicated `get_pane_cwd()` and `build_path()` across yazi/lazygit plugins, cache PATH in closures, cap `seen_windows` growth, and reduce log noise in input-method utility.

**Architecture:** Extract shared pane/process utilities into existing `utils/process.lua`. Both plugins require this module. Minor standalone fixes to events/input-method and utils/input-method.

**Tech Stack:** Lua (WezTerm config)

---

### Task 1: Add shared functions to `utils/process.lua`

**Files:**
- Modify: `utils/process.lua`

- [ ] **Step 1: Add `get_cwd()` and `build_path()` to the module**

Current `utils/process.lua`:
```lua
local M = {}

function M.foreground_matches(pane, names)
    local info = pane:get_foreground_process_info()
    if not info then
        return false
    end
    local name = info.name and info.name:lower() or ""
    for _, n in ipairs(names) do
        if name:find(n, 1, true) then
            return true
        end
    end
    if info.argv then
        for _, arg in ipairs(info.argv) do
            local lower = arg:lower()
            for _, n in ipairs(names) do
                if lower:find(n, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

return M
```

Replace with:
```lua
local wezterm = require("wezterm")
local os = require("os")

local M = {}

function M.get_cwd(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then return nil end
    if type(cwd) == 'userdata' or type(cwd) == 'table' then
        return cwd.file_path
    end
    if type(cwd) == 'string' and wezterm.url and wezterm.url.parse then
        local ok, url = pcall(wezterm.url.parse, cwd)
        if ok and url and url.file_path then return url.file_path end
    end
    if type(cwd) == 'string' then
        return (cwd:gsub('^file://[^/]*', ''))
    end
    return nil
end

function M.build_path(extra_paths)
    return table.concat(extra_paths, ":") .. ":" .. (os.getenv("PATH") or "")
end

function M.foreground_matches(pane, names)
    local info = pane:get_foreground_process_info()
    if not info then
        return false
    end
    local name = info.name and info.name:lower() or ""
    for _, n in ipairs(names) do
        if name:find(n, 1, true) then
            return true
        end
    end
    if info.argv then
        for _, arg in ipairs(info.argv) do
            local lower = arg:lower()
            for _, n in ipairs(names) do
                if lower:find(n, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

return M
```

- [ ] **Step 2: Commit**

```bash
git add utils/process.lua
git commit -m "feat: add get_cwd() and build_path() to utils/process

Extract duplicated pane-CWD and PATH-building logic from yazi and lazygit
plugins into a shared utility module.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 2: Update `config/plugins/yazi.lua`

**Files:**
- Modify: `config/plugins/yazi.lua`

- [ ] **Step 1: Replace local funcs with shared utils, cache PATH**

Replace the file content with:

```lua
local wezterm = require("wezterm")
local act = wezterm.action
local switch_to_english = require("config.utils.input-method").switch_to_english
local process = require("utils.process")

local M = {}

local DEFAULTS = {
    binary      = "/opt/homebrew/bin/yazi",
    log_level   = nil,
    extra_paths = { "/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin" },
}

local function resolve_opts(opts)
    opts = opts or {}
    local resolved = {
        binary      = opts.binary      or DEFAULTS.binary,
        extra_paths = opts.extra_paths or DEFAULTS.extra_paths,
    }
    if opts.log_level then
        resolved.log_level = opts.log_level
    end
    return resolved
end

local function make_open_fn(opts)
    local path = process.build_path(opts.extra_paths)
    return function(window, pane)
        switch_to_english()
        local cwd = process.get_cwd(pane)
        local env = { PATH = path }
        if opts.log_level then
            env.YAZI_LOG = opts.log_level
        end
        window:perform_action(act.SpawnCommandInNewTab {
            cwd  = cwd,
            args = { opts.binary },
            set_environment_variables = env,
        }, pane)
    end
end

-- Available immediately after require(), using defaults.
-- Replaced with resolved opts when setup() is called.
M.action = wezterm.action_callback(make_open_fn(DEFAULTS))

function M.setup(config, opts)
    local resolved = resolve_opts(opts)
    M.action = wezterm.action_callback(make_open_fn(resolved))
    config.keys = config.keys or {}
    table.insert(config.keys, {
        key    = "O",
        mods   = "CMD|SHIFT",
        action = M.action,
    })
end

return M
```

Key changes from current:
- Removed local `get_pane_cwd()` and `build_path()` (lines 13-31)
- Removed `local os = require("os")` (no longer needed)
- Added `local process = require("utils.process")`
- `process.get_cwd(pane)` replaces `get_pane_cwd(pane)`
- `process.build_path()` called once in `make_open_fn`, result cached in `path` closure variable

- [ ] **Step 2: Commit**

```bash
git add config/plugins/yazi.lua
git commit -m "refactor: use shared utils in yazi, cache PATH in closure

Replace local get_pane_cwd/build_path with utils.process equivalents.
Pre-compute PATH string in make_open_fn to avoid per-keypress recomputation.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 3: Update `config/plugins/lazygit.lua`

**Files:**
- Modify: `config/plugins/lazygit.lua`

- [ ] **Step 1: Replace local funcs with shared utils, cache PATH**

Replace the file content with:

```lua
local wezterm = require("wezterm")
local act = wezterm.action
local switch_to_english = require("config.utils.input-method").switch_to_english
local process = require("utils.process")

local M = {}

local DEFAULTS = {
    binary      = "/opt/homebrew/bin/lazygit",
    extra_paths = { "/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin" },
}

local function resolve_opts(opts)
    opts = opts or {}
    return {
        binary      = opts.binary      or DEFAULTS.binary,
        extra_paths = opts.extra_paths or DEFAULTS.extra_paths,
    }
end

local function make_open_fn(opts)
    local path = process.build_path(opts.extra_paths)
    return function(window, pane)
        switch_to_english()
        local cwd = process.get_cwd(pane)
        window:perform_action(act.SpawnCommandInNewTab {
            cwd  = cwd,
            args = { opts.binary },
            set_environment_variables = { PATH = path },
        }, pane)
    end
end

M.action = wezterm.action_callback(make_open_fn(DEFAULTS))

function M.setup(config, opts)
    local resolved = resolve_opts(opts)
    M.action = wezterm.action_callback(make_open_fn(resolved))
    config.keys = config.keys or {}
    table.insert(config.keys, {
        key    = "G",
        mods   = "CMD|SHIFT",
        action = M.action,
    })
end

return M
```

Key changes from current:
- Removed local `get_pane_cwd()` and `build_path()` (lines 12-30)
- Removed `local os = require("os")` (no longer needed)
- Added `local process = require("utils.process")`
- `process.get_cwd(pane)` replaces `get_pane_cwd(pane)`
- `process.build_path()` called once in `make_open_fn`, result cached in `path` closure variable

- [ ] **Step 2: Commit**

```bash
git add config/plugins/lazygit.lua
git commit -m "refactor: use shared utils in lazygit, cache PATH in closure

Replace local get_pane_cwd/build_path with utils.process equivalents.
Pre-compute PATH string in make_open_fn to avoid per-keypress recomputation.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 4: Cap `seen_windows` size in `config/events/input-method.lua`

**Files:**
- Modify: `config/events/input-method.lua`

- [ ] **Step 1: Add size cap to seen_windows**

Current `setup()` function:
```lua
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
```

Replace with:
```lua
local MAX_SEEN = 50

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

        -- Prevent unbounded growth: when hitting threshold, clear and re-populate.
        -- WezTerm does not expose mux:get_window() on the Lua side to check liveness.
        if #seen_windows >= MAX_SEEN then
            seen_windows = {}
        end

        seen_windows[id] = true
        im.switch_to_english()
    end)
end
```

Note: Lua tables used as sets don't track `#` reliably for non-array keys. Use a counter instead:

```lua
local MAX_SEEN = 50

function M.setup()
    local seen_windows = {}
    local seen_count = 0
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

        if seen_count >= MAX_SEEN then
            seen_windows = {}
            seen_count = 0
        end

        seen_windows[id] = true
        seen_count = seen_count + 1
        im.switch_to_english()
    end)
end
```

- [ ] **Step 2: Commit**

```bash
git add config/events/input-method.lua
git commit -m "fix: cap seen_windows table to prevent unbounded growth

Clear the seen_windows set when it reaches MAX_SEEN (50) entries.
Since WezTerm exposes no mux:get_window() on the Lua side, we cannot
check individual window liveness; clearing the entire set at a threshold
is a pragmatic tradeoff.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```

---

### Task 5: Reduce log level in `config/utils/input-method.lua`

**Files:**
- Modify: `config/utils/input-method.lua`

- [ ] **Step 1: Change per-candidate log_error to log_info**

In `config/utils/input-method.lua`, change line 22 from:
```lua
        wezterm.log_error("im-select failed: " .. tostring(result))
```
to:
```lua
        wezterm.log_info("im-select not found: " .. tostring(result))
```

The final fallback error on line 25 stays as `log_error`.

- [ ] **Step 2: Commit**

```bash
git add config/utils/input-method.lua
git commit -m "fix: reduce log level for expected im-select candidate misses

Per-candidate failures are expected (not all paths exist on every system).
Use log_info instead of log_error. Keep the final fallback at log_error.

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```
