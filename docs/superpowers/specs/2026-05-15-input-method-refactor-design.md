# Input Method Refactor Design

**Date:** 2026-05-15
**Status:** Approved

## Motivation

`config/events/input-method.lua` currently serves two roles:
1. Event handler — registers `window-focus-changed` to auto-switch input method
2. Utility — provides `set_english_input()` for plugins to call before spawning TUI apps

This violates single responsibility and forces plugins to `require("config.events.input-method")` — a module path that suggests it's an event handler, not a general-purpose utility.

## Design

### Module split

```
config/
  utils/
    input-method.lua    ← NEW: pure utility, exports switch_to_english()
  events/
    input-method.lua    ← MODIFIED: event registration only, delegates to utils
  plugins/
    yazi.lua            ← MODIFIED: require path updated
    lazygit.lua          ← MODIFIED: add switch_to_english() call
wezterm.lua             ← NO CHANGE
```

### `utils/input-method.lua` (new file)

Pure utility module. No event logic, no knowledge of callers.

**Exports:**
- `switch_to_english()` — locate `im-select` binary and run `im-select com.apple.keylayout.ABC`

**Internal logic** (moved from current `set_english_input()`):
1. Build candidate paths: `$IM_SELECT` → `/opt/homebrew/bin/im-select` → `/usr/local/bin/im-select` → `im-select` (PATH)
2. Try each candidate via `wezterm.run_child_process`
3. Return on first success, log errors on failure

### `events/input-method.lua` (modified)

Strips out `set_english_input()` and `ENGLISH_INPUT_ID`. `setup()` now delegates to the utility:

```lua
local im = require("utils.input-method")
-- window-focus-changed handler calls im.switch_to_english()
```

### Plugin changes

**yazi.lua:** Replace `require("config.events.input-method")` with `require("utils.input-method")`.

**lazygit.lua:** Add `require("utils.input-method").switch_to_english()` before `SpawnCommandInNewTab`, matching the yazi pattern.

## Files affected

| File | Change |
|------|--------|
| `config/utils/input-method.lua` | **Create** — extract `switch_to_english()` |
| `config/events/input-method.lua` | **Modify** — remove utility code, delegate to utils |
| `config/plugins/yazi.lua` | **Modify** — update require path |
| `config/plugins/lazygit.lua` | **Modify** — add input method switch |
| `wezterm.lua` | **No change** |
