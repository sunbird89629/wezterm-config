local wezterm = require("wezterm")
local os = require("os")

local M = {}

function M.get_cwd(pane)
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

function M.build_path(extra_paths)
    return table.concat(extra_paths, ":") .. ":" .. (os.getenv("PATH") or "")
end

function M.foreground_matches(pane, names)
    local info = pane:get_foreground_process_info()
    if not info then
        return false
    end
    local name = info.name and info.name:lower() or ""
    for _, n in ipairs(names) do
        if name:find(n, 1, true) then
            return true
        end
    end
    if info.argv then
        for _, arg in ipairs(info.argv) do
            local lower = arg:lower()
            for _, n in ipairs(names) do
                if lower:find(n, 1, true) then
                    return true
                end
            end
        end
    end
    return false
end

return M
