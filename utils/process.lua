local M = {}

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
