# Config Directory Reorganization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize `config/` from a flat structure into `styles/`, `behaviors/`, and `plugins/` subdirectories.

**Architecture:** Move 6 Lua config files into 2 new subdirectories, update 7 require paths across 2 files. No functional changes.

**Tech Stack:** Lua, WezTerm

---

### Task 1: Create subdirectories

- [ ] **Step 1: Create styles/ and behaviors/ directories**

```bash
mkdir -p config/styles config/behaviors
```

- [ ] **Step 2: Verify directories exist**

```bash
ls -d config/styles config/behaviors
```

Expected: both directories listed

- [ ] **Step 3: Commit**

```bash
git add config/styles config/behaviors
git commit -m "chore: create styles/ and behaviors/ subdirectories in config/"
```

---

### Task 2: Move style files to styles/

- [ ] **Step 1: Move appearance.lua**

```bash
git mv config/appearance.lua config/styles/appearance.lua
```

- [ ] **Step 2: Move fonts.lua**

```bash
git mv config/fonts.lua config/styles/fonts.lua
```

- [ ] **Step 3: Move command_palette.lua**

```bash
git mv config/command_palette.lua config/styles/command_palette.lua
```

- [ ] **Step 4: Verify moves**

```bash
ls config/styles/
```

Expected: `appearance.lua  command_palette.lua  fonts.lua`

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move style configs to config/styles/"
```

---

### Task 3: Move behavior files to behaviors/

- [ ] **Step 1: Move bindings.lua**

```bash
git mv config/bindings.lua config/behaviors/bindings.lua
```

- [ ] **Step 2: Move domains.lua**

```bash
git mv config/domains.lua config/behaviors/domains.lua
```

- [ ] **Step 3: Move hyperlinks.lua**

```bash
git mv config/hyperlinks.lua config/behaviors/hyperlinks.lua
```

- [ ] **Step 4: Verify moves**

```bash
ls config/behaviors/
```

Expected: `bindings.lua  domains.lua  hyperlinks.lua`

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: move behavior configs to config/behaviors/"
```

---

### Task 4: Update require paths in wezterm.lua

- [ ] **Step 1: Update style require paths**

In `wezterm.lua`, change lines 17-19 and 31:

| Line | Old | New |
|------|-----|-----|
| 17 | `require("config.appearance").setup(config)` | `require("config.styles.appearance").setup(config)` |
| 18 | `require("config.fonts").setup(config)` | `require("config.styles.fonts").setup(config)` |
| 31 | `require("config.command_palette").setup(config)` | `require("config.styles.command_palette").setup(config)` |

- [ ] **Step 2: Update behavior require paths**

In `wezterm.lua`, change lines 25, 27, 29:

| Line | Old | New |
|------|-----|-----|
| 25 | `require("config.bindings").setup(config)` | `require("config.behaviors.bindings").setup(config)` |
| 27 | `require("config.domains").setup(config)` | `require("config.behaviors.domains").setup(config)` |
| 29 | `require("config.hyperlinks").setup(config)` | `require("config.behaviors.hyperlinks").setup(config)` |

- [ ] **Step 3: Verify all 6 paths updated**

```bash
grep -n "config\.\(appearance\|fonts\|command_palette\|bindings\|domains\|hyperlinks\)" wezterm.lua
```

Expected: no output (all old paths gone)

```bash
grep -n "config\.styles\.\|config\.behaviors\." wezterm.lua
```

Expected: 6 lines showing new paths

- [ ] **Step 4: Commit**

```bash
git add wezterm.lua
git commit -m "refactor: update require paths for config reorganization"
```

---

### Task 5: Update require path in events/new-tab-button.lua

- [ ] **Step 1: Update domains require**

In `events/new-tab-button.lua` line 3, change:

```lua
-- Old:
local domains = require('config.domains')
-- New:
local domains = require('config.behaviors.domains')
```

- [ ] **Step 2: Verify path updated**

```bash
grep "config\.domains" events/new-tab-button.lua
```

Expected: no output

```bash
grep "config\.behaviors\.domains" events/new-tab-button.lua
```

Expected: 1 line

- [ ] **Step 3: Commit**

```bash
git add events/new-tab-button.lua
git commit -m "refactor: update domains require path in new-tab-button event"
```

---

### Task 6: Clean up empty directories and verify

- [ ] **Step 1: Check no stale files remain in old locations**

```bash
ls config/appearance.lua config/fonts.lua config/command_palette.lua config/bindings.lua config/domains.lua config/hyperlinks.lua 2>&1
```

Expected: all "No such file or directory"

- [ ] **Step 2: Verify final directory structure**

```bash
find config -type f -name "*.lua" | sort
```

Expected:
```
config/behaviors/bindings.lua
config/behaviors/domains.lua
config/behaviors/hyperlinks.lua
config/command_palette.lua   ← should NOT exist
config/init.lua
config/plugins/ai_helper.lua
config/plugins/bar.lua
config/plugins/demo_palette.lua
config/plugins/image_paste.lua
config/plugins/modal.lua
config/plugins/quick_domains.lua
config/plugins/quota_limit.lua
config/plugins/replay.lua
config/plugins/tabline.lua
config/plugins/temp_demo_menu.lua
config/plugins/temp_edit.lua
config/plugins/toggle_terminal.lua
config/styles/appearance.lua
config/styles/command_palette.lua
config/styles/fonts.lua
```

- [ ] **Step 3: Reload WezTerm to verify no breakage**

Manually reload WezTerm config (Cmd+Shift+R or `wezterm cli reload`). If the terminal works without errors, the reorganization is complete.
