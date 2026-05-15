local wezterm = require("wezterm")
local act = wezterm.action
local os = require("os")

local M = {}

local DEFAULTS = {
    binary      = "/opt/homebrew/bin/yazi",
    log_level   = nil,
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
    local resolved = {
        binary      = opts.binary      or DEFAULTS.binary,
        extra_paths = opts.extra_paths or DEFAULTS.extra_paths,
    }
    if opts.log_level then
        resolved.log_level = opts.log_level
    end
    return resolved
end

local function make_open_fn(opts)
    return function(window, pane)
        require("config.utils.input-method").switch_to_english()
        local cwd = get_pane_cwd(pane)
        local env = { PATH = build_path(opts.extra_paths) }
        if opts.log_level then
            env.YAZI_LOG = opts.log_level
        end
        window:perform_action(act.SpawnCommandInNewTab {
            cwd  = cwd,
            args = { opts.binary },
            set_environment_variables = env,
        }, pane)
    end
end

-- Available immediately after require(), using defaults.
-- Replaced with resolved opts when setup() is called.
M.action = wezterm.action_callback(make_open_fn(DEFAULTS))

function M.setup(config, opts)
    local resolved = resolve_opts(opts)
    M.action = wezterm.action_callback(make_open_fn(resolved))
    config.keys = config.keys or {}
    table.insert(config.keys, {
        key    = "O",
        mods   = "CMD|SHIFT",
        action = M.action,
    })
end

return M
