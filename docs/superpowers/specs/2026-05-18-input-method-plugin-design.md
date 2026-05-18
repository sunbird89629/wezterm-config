# Design: input-method Plugin

**Date:** 2026-05-18
**Status:** Approved

## Goal

Refactor the input-method event handler from `config/events/input-method.lua` into a plugin following the standard plugin convention (`config/plugins/input_method.lua`), making it consistent with how lazygit, yazi, and other plugins are structured.

## Background

The input-method feature is currently split across two files:

- `config/utils/input-method.lua` — pure utility; calls `im-select` to switch macOS input source to English. Shared by lazygit and yazi.
- `config/events/input-method.lua` — registers a `window-focus-changed` event handler that calls the utility on first focus per window.

The event handler is a side-effectful wiring concern, which belongs in `config/plugins/`, not `config/events/`.

## Design

### File changes

| File | Action |
|------|--------|
| `config/plugins/input_method.lua` | Create — absorbs event handler logic |
| `config/events/input-method.lua` | Delete |
| `wezterm.lua` | Update require line |
| `config/utils/input-method.lua` | No change |

### Plugin interface

```lua
-- config/plugins/input_method.lua

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

### wezterm.lua change

```lua
-- Before
require("config.events.input-method").setup()

-- After
require("config.plugins.input_method").setup(config)
```

`config` is passed as first arg to match the plugin convention, even though this plugin does not modify the config table.

### Utility stays unchanged

`config/utils/input-method.lua` is not modified. Lazygit and yazi import from it directly and that import path remains valid.

## Decisions

- **`event` is the only configurable option** — binary path and input ID are concerns of the utility, not the plugin. Adding them here would duplicate what the utility already owns.
- **`config` is accepted but unused** — consistent with the plugin convention; all plugins take `config` as the first argument.
- **`seen_windows` state is local to `setup()`** — same as current implementation; avoids module-level mutable state.

## Out of scope

- Making the utility configurable (binary path, input ID) — separate concern.
- Supporting additional events (e.g. `gui-startup`) — can be added later via opts.
