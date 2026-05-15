local wezterm = require("wezterm")
local act = wezterm.action
local switch_to_english = require("config.utils.input-method").switch_to_english
local process = require("utils.process")

local M = {}

local DEFAULTS = {
    binary      = "/opt/homebrew/bin/lazygit",
    extra_paths = { "/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin" },
}

local function resolve_opts(opts)
    opts = opts or {}
    return {
        binary      = opts.binary      or DEFAULTS.binary,
        extra_paths = opts.extra_paths or DEFAULTS.extra_paths,
    }
end

local function make_open_fn(opts)
    local path = process.build_path(opts.extra_paths)
    return function(window, pane)
        switch_to_english()
        local cwd = process.get_cwd(pane)
        window:perform_action(act.SpawnCommandInNewTab {
            cwd  = cwd,
            args = { opts.binary },
            set_environment_variables = { PATH = path },
        }, pane)
    end
end

M.action = wezterm.action_callback(make_open_fn(DEFAULTS))

function M.setup(config, opts)
    local resolved = resolve_opts(opts)
    M.action = wezterm.action_callback(make_open_fn(resolved))
    config.keys = config.keys or {}
    table.insert(config.keys, {
        key    = "G",
        mods   = "CMD|SHIFT",
        action = M.action,
    })
end

return M
