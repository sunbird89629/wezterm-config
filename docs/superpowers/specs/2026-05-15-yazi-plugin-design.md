# Yazi Plugin — Design Spec

**Date:** 2026-05-15
**Status:** Approved

## Goal

Extract the yazi file-manager integration from `config/plugins/temp_edit.lua` into a standalone, configurable module `config/plugins/yazi.lua`. The new module exposes a reusable `action` field so other consumers (e.g., command palette) can reference it without duplicating logic.

## File Changes

| File | Change |
|------|--------|
| `config/plugins/yazi.lua` | New file — full yazi integration |
| `config/plugins/temp_edit.lua` | Remove `open_yazi`, `get_pane_cwd`, CMD+SHIFT+O binding; wire command palette `file` entry to `yazi.action` |
| `wezterm.lua` | Add `require("config.plugins.yazi").setup(config)` |

## Public API

```lua
local yazi = require("config.plugins.yazi")

yazi.setup(config, opts)
-- opts fields (all optional):
--   binary      string   path to yazi binary       default: "/opt/homebrew/bin/yazi"
--   log_level   string   YAZI_LOG value             default: nil (disabled)
--   extra_paths table    path prefixes to prepend   default: { "/opt/homebrew/bin",
--                                                              "/opt/homebrew/sbin",
--                                                              "/usr/local/bin" }

yazi.action
-- wezterm.action_callback, ready to use in key tables or command palette
```

`setup` registers the `CMD+SHIFT+O` keybinding. Callers that only need the action (e.g., command palette) can skip `setup` and reference `yazi.action` directly after `require`.

## Internal Structure

### `get_pane_cwd(pane) → string|nil`
Migrated verbatim from `temp_edit.lua`. Resolves the pane's current working directory across both the legacy URI-string format and the newer Url-object format. Private to this module.

### `build_path(extra_paths) → string`
Prepends each entry in `extra_paths` to `os.getenv("PATH")`, unconditionally. Duplicates in PATH are harmless. Returns the resulting PATH string.

### `make_open_fn(opts) → function(window, pane)`
Closes over the resolved opts and returns the action handler. Called once during module load to produce `M.action`.

## Key Binding

`CMD+SHIFT+O` registered inside `setup` via `table.insert(config.keys, ...)`, consistent with how other bindings in `temp_edit.lua` are registered.

## Command Palette Integration

The `file` entry in `PALETTE_COMMANDS` (in `temp_edit.lua`) currently shows a toast placeholder. After this change it will execute `yazi.action` instead. The command palette callback's `elseif id == 'file'` branch calls `win:perform_action(yazi.action, p)`.

## Default Values

```lua
local DEFAULTS = {
    binary      = "/opt/homebrew/bin/yazi",
    log_level   = nil,
    extra_paths = { "/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin" },
}
```

`log_level = nil` means `YAZI_LOG` is not set in the spawned environment. Pass `"debug"` explicitly when diagnosing issues.

## Error Handling

No explicit error handling needed: `get_pane_cwd` already returns `nil` gracefully (yazi opens in the default directory), and `SpawnCommandInNewTab` is fire-and-forget.

## Out of Scope

- Configuring the yazi keymaps or yazi's own config files
- Multiple yazi instances or workspace management
- Restoring yazi state across WezTerm restarts
