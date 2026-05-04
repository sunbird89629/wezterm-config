# Config Directory Reorganization

## Goal

Reorganize `config/` directory from a flat structure into three categorized subdirectories: `styles/`, `behaviors/`, and `plugins/` (existing).

## Current Structure

```
config/
├── init.lua              (unused Config class, dead code — keep as-is)
├── appearance.lua        (window style, colors, tab bar)
├── fonts.lua             (font configuration)
├── command_palette.lua   (command palette styling)
├── bindings.lua          (keybindings)
├── domains.lua           (SSH domains)
├── hyperlinks.lua        (hyperlink rules)
└── plugins/
    ├── ai_helper.lua
    ├── bar.lua
    ├── demo_palette.lua
    ├── image_paste.lua
    ├── modal.lua
    ├── quick_domains.lua
    ├── quota_limit.lua
    ├── replay.lua
    ├── tabline.lua
    ├── temp_demo_menu.lua
    ├── temp_edit.lua
    └── toggle_terminal.lua
```

## Target Structure

```
config/
├── init.lua              (keep in place)
├── styles/
│   ├── appearance.lua
│   ├── fonts.lua
│   └── command_palette.lua
├── behaviors/
│   ├── bindings.lua
│   ├── domains.lua
│   └── hyperlinks.lua
└── plugins/              (unchanged)
    ├── ai_helper.lua
    ├── ...
```

## File Moves

| Source | Destination |
|--------|-------------|
| `config/appearance.lua` | `config/styles/appearance.lua` |
| `config/fonts.lua` | `config/styles/fonts.lua` |
| `config/command_palette.lua` | `config/styles/command_palette.lua` |
| `config/bindings.lua` | `config/behaviors/bindings.lua` |
| `config/domains.lua` | `config/behaviors/domains.lua` |
| `config/hyperlinks.lua` | `config/behaviors/hyperlinks.lua` |

## Require Path Updates

### `wezterm.lua` (6 changes)

| Old | New |
|-----|-----|
| `require("config.appearance")` | `require("config.styles.appearance")` |
| `require("config.fonts")` | `require("config.styles.fonts")` |
| `require("config.command_palette")` | `require("config.styles.command_palette")` |
| `require("config.bindings")` | `require("config.behaviors.bindings")` |
| `require("config.domains")` | `require("config.behaviors.domains")` |
| `require("config.hyperlinks")` | `require("config.behaviors.hyperlinks")` |

### `events/new-tab-button.lua` (1 change)

| Old | New |
|-----|-----|
| `require('config.domains')` | `require('config.behaviors.domains')` |

### No change needed

- `config/behaviors/bindings.lua` references `config.plugins.image_paste` — path unchanged since `plugins/` stays in place.

## Not Changed

- `config/init.lua` — retained at root (dead code, user chose to keep)
- `config/plugins/` — no structural changes
- `events/` — no changes (except new-tab-button.lua path fix)
- `utils/` — no changes

## Approach

Direct file moves + require path updates. No functional changes. No new init.lua aggregators.
