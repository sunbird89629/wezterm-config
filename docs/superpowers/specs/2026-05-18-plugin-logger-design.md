# Plugin Logger Design

Date: 2026-05-18

## Problem

Plugins currently call `wezterm.log_info()` / `wezterm.log_error()` directly with no
prefix and no way to silence them per plugin. When multiple plugins log simultaneously,
it's impossible to tell which plugin produced which line.

## Goals

- Give every log line a `[plugin_name]` prefix
- Let each plugin be silenced independently via `opts.verbose = false` (default)
- Enable debug logging per plugin by passing `opts.verbose = true` at the call site
- No new dependencies: output goes through `wezterm.log_*` built-ins only

## Non-Goals

- Log levels (debug/info/warn/error filtering) — binary on/off is sufficient
- File output — `wezterm.log_*` + debug overlay is enough
- Global log switch — per-plugin control is preferred

## Architecture

### New file

**`config/utils/logger.lua`** — Logger factory. Single public function: `Logger.new(name, enabled)`.

### Modified files

- `config/plugins/input_method.lua` — create logger inside `setup()`, pass to util
- `config/utils/input-method.lua` — `switch_to_english(log)` receives logger as parameter

Other plugins (`bar`, `yazi`, `lazygit`, etc.) have no log calls today; they adopt this
pattern only when they add logging.

## API

```lua
local Logger = require("config.utils.logger")

-- Inside plugin setup():
local log = Logger.new("input_method", opts and opts.verbose or false)

log.info("switched to English")   -- → wezterm.log_info("[input_method] switched to English")
log.error("no im-select found")   -- → wezterm.log_error("[input_method] no im-select found")
```

`Logger.new(name, enabled)`:
- `name` — string prefix, appears as `[name]` in every message
- `enabled` — boolean; `false` (default) silences all output, `true` prints everything
- Returns a table with `.info(msg)` and `.error(msg)` methods
- Messages are `tostring()`-coerced to prevent runtime errors on non-string values

## Usage by callers

`wezterm.lua` passes opts to enable logging during debugging:

```lua
-- Normal (silent):
require("config.plugins.input_method").setup(config)

-- Debug session:
require("config.plugins.input_method").setup(config, { verbose = true })
```

## Logger implementation (reference)

```lua
local wezterm = require("wezterm")
local Logger = {}

function Logger.new(name, enabled)
    local prefix = "[" .. name .. "] "
    if not enabled then
        return { info = function() end, error = function() end }
    end
    return {
        info  = function(msg) wezterm.log_info(prefix .. tostring(msg)) end,
        error = function(msg) wezterm.log_error(prefix .. tostring(msg)) end,
    }
end

return Logger
```

## Migration: `switch_to_english`

Before:
```lua
function M.switch_to_english()
    -- ...
    wezterm.log_info("im-select not found: " .. tostring(result))
    wezterm.log_error("Failed to switch input method; set IM_SELECT or fix PATH.")
end
```

After:
```lua
function M.switch_to_english(log)
    -- ...
    log.info("im-select not found: " .. tostring(result))
    log.error("Failed to switch input method; set IM_SELECT or fix PATH.")
end
```

The logger is created in `input_method.lua`'s `setup()` and passed down. No global state.
