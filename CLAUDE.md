# WezTerm Config

## Structure
- `wezterm.lua` — entry point; loads all modules via `require()`
- `config/styles/` — appearance, fonts, tab bar
- `config/behaviors/` — keybindings, domains, hyperlinks
- `config/events/` — event handlers (input-method, open-uri)
- `config/plugins/` — plugin wrappers (bar, lazygit, yazi, replay, etc.)
- `config/utils/` — shared helpers (e.g., input-method switcher)
- `utils/` — lower-level helpers (platform detection, process)
- `wezterm-types/` — git submodule for Lua type definitions

## Dev Workflow
- No build step; reload WezTerm or run `wezterm --config-file wezterm.lua` to test
- Lint: `luacheck .`
- Format: `stylua .` (3-space indent, single quotes, 100-col limit)
- Type hints: `---@type Wezterm` / `---@type Config` patterns used throughout

## Gotchas
- `hide_tab_bar_if_only_one_tab = true` causes tab-open lag — keep it `false`
- `automatically_reload_config = false` is intentional (manual reload preferred)
- Local secrets go in `secrets.lua` (gitignored) — never commit credentials
- Several plugins are disabled (commented out in `wezterm.lua`) — check there before adding
- `config.key_tables` must be seeded from `wezterm.gui.default_key_tables()` before inserting entries

## Commit Style
Conventional Commits: `feat(plugin): ...`, `fix(input-method): ...`, `chore: ...`
