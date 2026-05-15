local wezterm = require("wezterm")
local act = wezterm.action
local os = require("os")

local M = {}

local DEFAULTS = {
    binary      = "/opt/homebrew/bin/lazygit",
    extra_paths = { "/opt/homebrew/bin", "/opt/homebrew/sbin", "/usr/local/bin" },
}

local function get_pane_cwd(pane)
    local cwd = pane:get_current_working_dir()
    if not cwd then return nil end
    if type(cwd) == 'userdata' or type(cwd) == 'table' then
        return cwd.file_path
    end
    if type(cwd) == 'string' and wezterm.url and wezterm.url.parse then
        local ok, url = pcall(wezterm.url.parse, cwd)
        if ok and url and url.file_path then return url.file_path end
    end
    if type(cwd) == 'string' then
        return (cwd:gsub('^file://[^/]*', ''))
    end
    return nil
end

local function build_path(extra_paths)
    return table.concat(extra_paths, ":") .. ":" .. (os.getenv("PATH") or "")
end

local function resolve_opts(opts)
    opts = opts or {}
    return {
        binary      = opts.binary      or DEFAULTS.binary,
        extra_paths = opts.extra_paths or DEFAULTS.extra_paths,
    }
end

local function make_open_fn(opts)
    return function(window, pane)
        local cwd = get_pane_cwd(pane)
        window:perform_action(act.SpawnCommandInNewTab {
            cwd  = cwd,
            args = { opts.binary },
            set_environment_variables = { PATH = build_path(opts.extra_paths) },
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
