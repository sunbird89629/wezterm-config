# Plugin Cleanup Design

**Date:** 2026-05-15
**Status:** Approved

## Motivation

The simplify code review surfaced several pre-existing issues in the WezTerm config:

1. `get_pane_cwd()` and `build_path()` are duplicated verbatim in `yazi.lua` and `lazygit.lua`
2. `build_path()` recomputes `table.concat` + `os.getenv("PATH")` on every keypress
3. `seen_windows` in `events/input-method.lua` grows unboundedly (never prunes closed windows)
4. `utils/input-method.lua` logs at `log_error` for expected candidate failures (noise)

## Design

### 1. Extract shared functions to `utils/process.lua`

`utils/process.lua` currently exports only `foreground_matches()`. Add two more:

- `get_cwd(pane)` — resolve pane working directory from `pane:get_current_working_dir()`
- `build_path(extra_paths)` — prepend extra paths to system PATH

Both are taken verbatim from `yazi.lua` (the canonical versions).

### 2. De-duplicate plugins

**yazi.lua** and **lazygit.lua** both:

- Remove local `get_pane_cwd()` and `build_path()` definitions
- Add `local process = require("utils.process")` at module scope
- Use `process.get_cwd(pane)` and `process.build_path(...)` in callbacks

### 3. Cache `PATH` in closure

In both plugins' `make_open_fn`, pre-compute the full PATH string once and capture it in the closure:

```lua
local function make_open_fn(opts)
    local path = process.build_path(opts.extra_paths)
    return function(window, pane)
        -- use path directly, no recomputation
    end
end
```

### 4. Prune stale `seen_windows` entries

In `events/input-method.lua`, before adding a new window ID, scan existing entries and remove any whose window no longer exists. WezTerm does not expose `mux:get_window(id)` on the Lua side, so instead use a size cap: when `seen_windows` exceeds a threshold (e.g., 50 entries), clear it entirely. This is a pragmatic tradeoff — the table re-populates as windows focus, and the cap prevents unbounded growth.

### 5. Reduce log level in `utils/input-method.lua`

Change per-candidate failure logs from `wezterm.log_error` to `wezterm.log_info`. Keep the final "Failed to switch" at `log_error`.

## Files affected

| File | Change |
|------|--------|
| `utils/process.lua` | **Modify** — add `get_cwd()`, `build_path()` |
| `config/plugins/yazi.lua` | **Modify** — use shared functions, cache PATH |
| `config/plugins/lazygit.lua` | **Modify** — use shared functions, cache PATH |
| `config/events/input-method.lua` | **Modify** — cap `seen_windows` size |
| `config/utils/input-method.lua` | **Modify** — reduce log level |
