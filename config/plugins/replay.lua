local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    local wezterm_replay = wezterm.plugin.require("https://github.com/btrachey/wezterm-replay")
    
    wezterm_replay.apply_to_config(config, {
        -- 您可以根据喜好修改快捷键，默认是 LEADER + r 和 LEADER + q
        -- replay_key = 'r',
        -- recall_key = 'q',
        
        -- 示例：如果想要自定义提取器可以写在这里
        extractors = {
            -- 默认已经包含了 URL 和 反引号提取
        }
    })
end

return M
