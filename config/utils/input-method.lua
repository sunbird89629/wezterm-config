local wezterm = require("wezterm")

local M = {}

local ENGLISH_INPUT_ID = "com.apple.keylayout.ABC"

function M.switch_to_english()
    local candidates = {}
    local env_path = os.getenv("IM_SELECT")
    if env_path and env_path ~= "" then
        table.insert(candidates, env_path)
    end
    table.insert(candidates, "/opt/homebrew/bin/im-select")
    table.insert(candidates, "/usr/local/bin/im-select")
    table.insert(candidates, "im-select")

    for _, im_select in ipairs(candidates) do
        local ok, result = pcall(wezterm.run_child_process, {im_select, ENGLISH_INPUT_ID})
        if ok then
            return
        end
        wezterm.log_error("im-select failed: " .. tostring(result))
    end

    wezterm.log_error("Failed to switch input method; set IM_SELECT or fix PATH.")
end

return M
