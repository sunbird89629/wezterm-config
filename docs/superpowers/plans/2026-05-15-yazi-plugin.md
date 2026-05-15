# Yazi Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract the yazi file-manager integration from `temp_edit.lua` into a standalone configurable module `config/plugins/yazi.lua` that exports a reusable `action` field.

**Architecture:** Create `yazi.lua` with private helpers (`get_pane_cwd`, `build_path`, `make_open_fn`) and a public API (`M.action`, `M.setup`). Remove the yazi-related code from `temp_edit.lua` and wire the command palette `file` entry to `yazi.action`. Register the module in `wezterm.lua`.

**Tech Stack:** WezTerm Lua config, wezterm API (`act.SpawnCommandInNewTab`, `wezterm.action_callback`)

---

## File Map

| File | Action | What changes |
|------|--------|--------------|
| `config/plugins/yazi.lua` | Create | Full yazi module |
| `config/plugins/temp_edit.lua` | Modify | Remove `get_pane_cwd`, `open_yazi`, CMD+SHIFT+O binding; add `file` branch in command palette |
| `wezterm.lua` | Modify | Add `require("config.plugins.yazi").setup(config)` |

---

## Task 1: Create `config/plugins/yazi.lua`

**Files:**
- Create: `config/plugins/yazi.lua`

- [ ] **Step 1: Write the file**

```lua
local wezterm = require("wezterm")
local act = wezterm.action
local os = require("os")

local M = {}

local DEFAULTS = {
    binary      = "/opt/homebrew/bin/yazi",
    log_level   = nil,
    extra_paths = { "/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin" },
}

local function get_pane_cwd(pane)
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

local function build_path(extra_paths)
    return table.concat(extra_paths, ":") .. ":" .. (os.getenv("PATH") or "")
end

local function resolve_opts(opts)
    opts = opts or {}
    return {
        binary      = opts.binary      or DEFAULTS.binary,
        log_level   = opts.log_level,
        extra_paths = opts.extra_paths or DEFAULTS.extra_paths,
    }
end

local function make_open_fn(opts)
    return function(window, pane)
        local cwd = get_pane_cwd(pane)
        local env = { PATH = build_path(opts.extra_paths) }
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

- [ ] **Step 2: Verify syntax**

```bash
/opt/homebrew/bin/wezterm --config-file /dev/null \
  lua -e 'dofile("/Users/hao/.config/wezterm/config/plugins/yazi.lua")'
```

WezTerm bundles a Lua interpreter accessible via the CLI. If the above path doesn't work, check with `which wezterm`. Expected: no output (no syntax error).

Alternative quick check:
```bash
lua /Users/hao/.config/wezterm/config/plugins/yazi.lua 2>&1 | head -5
```
Expected: may complain about `wezterm` module not found (that's OK — it means Lua parsed it fine and got to the require call).

- [ ] **Step 3: Commit**

```bash
git add config/plugins/yazi.lua
git commit -m "feat: add yazi plugin module with configurable opts and exported action"
```

---

## Task 2: Update `config/plugins/temp_edit.lua`

**Files:**
- Modify: `config/plugins/temp_edit.lua`

Three independent removals + one addition.

- [ ] **Step 1: Add yazi require at top of file**

After line 6 (`local os = require("os")`), add:

```lua
local yazi = require("config.plugins.yazi")
```

The top of the file should look like:

```lua
local wezterm = require("wezterm")
local time = wezterm.time
local act = wezterm.action
local mux = wezterm.mux
local io = require("io")
local os = require("os")
local yazi = require("config.plugins.yazi")
```

- [ ] **Step 2: Remove `get_pane_cwd`**

Delete the entire function (lines 43–68 in the original; find by content):

```lua
local function get_pane_cwd(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then
        return nil
    end

    -- New version might be a Url object
    if type(cwd) == 'userdata' or type(cwd) == 'table' then
        return cwd.file_path
    end

    -- Old version is URI string
    if type(cwd) == 'string' and wezterm.url and wezterm.url.parse then
        local ok, url = pcall(wezterm.url.parse, cwd)
        if ok and url and url.file_path then
            return url.file_path
        end
    end

    -- Fallback: strip file:// prefix
    if type(cwd) == 'string' then
        return (cwd:gsub('^file://[^/]*', ''))
    end

    return nil
end
```

- [ ] **Step 3: Remove `open_yazi`**

Delete the entire function:

```lua
local function open_yazi(window, pane)
    local cwd = get_pane_cwd(pane)
    -- SpawnCommandInNewTab 不走 shell 初始化，前插常用工具目录确保 fzf/code 等可见
    local path = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:" .. (os.getenv("PATH") or "")
    window:perform_action(act.SpawnCommandInNewTab {
        cwd = cwd,
        args = {'/opt/homebrew/bin/yazi'},
        set_environment_variables = { PATH = path, YAZI_LOG = "debug" }
    }, pane)
end
```

- [ ] **Step 4: Remove CMD+SHIFT+O binding from `M.setup`**

In `M.setup`, delete:

```lua
    -- Command+Shift+O: Open Yazi
    table.insert(config.keys, {
        key = "O",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(open_yazi)
    })
```

- [ ] **Step 5: Wire command palette `file` entry to `yazi.action`**

In the command palette `action` callback, change the `else` branch:

Before:
```lua
            else
                win:toast_notification('Demo', 'Selected: ' .. label, nil, 2000)
            end
```

After:
```lua
            elseif id == 'file' then
                win:perform_action(yazi.action, p)
            else
                win:toast_notification('Demo', 'Selected: ' .. label, nil, 2000)
            end
```

- [ ] **Step 6: Commit**

```bash
git add config/plugins/temp_edit.lua
git commit -m "refactor: remove yazi code from temp_edit, wire palette file entry to yazi.action"
```

---

## Task 3: Update `wezterm.lua`

**Files:**
- Modify: `wezterm.lua`

- [ ] **Step 1: Add yazi setup call**

In `wezterm.lua`, add the yazi setup line immediately before the `temp_edit` line:

Before:
```lua
require("config.plugins.temp_edit").setup(config)
```

After:
```lua
require("config.plugins.yazi").setup(config)
require("config.plugins.temp_edit").setup(config)
```

The full plugins section should now look like:

```lua
require("config.plugins.bar").setup(config)
-- require("config.plugins.tabline").setup(config)
require("config.plugins.replay").setup(config)
require("config.plugins.toggle_terminal").setup(config)
require("config.plugins.quick_domains").setup(config)
-- require("config.plugins.quota_limit").setup(config)
require("config.plugins.ai_helper").setup(config)
-- require("config.plugins.temp_demo_menu").setup(config)
require("config.plugins.yazi").setup(config)
require("config.plugins.temp_edit").setup(config)
-- require("config.plugins.modal").setup(config)
```

- [ ] **Step 2: Reload WezTerm and verify**

Press `Cmd+Shift+R` to reload config (or restart WezTerm).

Check 1 — `CMD+SHIFT+O` opens yazi in a new tab:
- Press `CMD+SHIFT+O`
- Expected: new tab opens, yazi starts in the current pane's directory

Check 2 — command palette `File Explorer` entry works:
- Press `CMD+SHIFT+P` → select "File Explorer"
- Expected: new tab opens with yazi (same as above)

Check 3 — fzf works inside yazi:
- Inside yazi, trigger file search (default key: `f` or `/`)
- Expected: fzf prompt appears

- [ ] **Step 3: Commit**

```bash
git add wezterm.lua
git commit -m "feat: register yazi plugin in wezterm.lua"
```

---

## Task 4: Push

- [ ] **Push all commits**

```bash
git push
```
