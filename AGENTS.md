# Repository Guidelines

## Project Structure & Module Organization
- `wezterm.lua` is the main entrypoint that loads the modular config.
- `config/` holds feature-focused modules (appearance, bindings, domains, plugins).
- `events/` contains event handlers (status, tab titles, GUI startup).
- `utils/` contains shared helpers used across config and plugins.
- `wezterm-types/` is a git submodule providing Lua type definitions.
- `.github/` contains assets like screenshots referenced in `README.md`.

## Build, Test, and Development Commands
This repository is a WezTerm configuration; there is no build step. Typical workflows:
- `wezterm` (or launch WezTerm normally) loads `~/.config/wezterm/wezterm.lua`.
- `luacheck .` runs linting with `.luacheckrc`.
- `stylua .` formats Lua files using `.stylua.toml`.
- `git submodule update --init --recursive` fetches `wezterm-types/` if needed.

## Coding Style & Naming Conventions
- LuaJIT syntax, spaces with 3-space indentation (`.stylua.toml`).
- Prefer single quotes where possible; keep lines under 100 columns when formatting.
- Modules are named by responsibility: `config/*.lua`, `events/*.lua`, `utils/*.lua`.
- Keep config tables declarative; isolate reusable logic in `utils/`.

## Testing Guidelines
- No automated test suite is defined for this repo.
- Validate changes by reloading WezTerm and exercising the affected feature.
- For UI changes, verify status/tab rendering and update `.github/screenshots` if needed.

## Commit & Pull Request Guidelines
- Follow Conventional Commits style: `feat(ui): ...`, `chore: ...`, `fix(input-method): ...`.
- Keep commits scoped to one change area (e.g., one plugin or event).
- PRs should include a short summary, affected modules, and screenshots for UI changes.
- Link relevant issues or discussions when behavior changes.

## Configuration Tips
- Customize domains in `config/domains.lua`.
- Keep secrets out of the repo; prefer local overrides or environment variables.
