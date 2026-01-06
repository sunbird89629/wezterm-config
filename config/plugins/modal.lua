local wezterm = require("wezterm")
local M = {}

function M.setup(config)

    local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")

    -- 1) 生成带 hints 的 status_text，并注册 UI / Scroll / copy_mode（以及 search/visual 的提示）
    modal.apply_to_config(config)

    -- 2) 默认快捷键：ALT-u(UI) / ALT-c(Copy) / ALT-n(Scroll)
    modal.set_default_keys(config)

    -- 3) 关键：进入/退出 mode 时更新右上角状态栏（显示快捷键提示）
    -- wezterm.on("modal.enter", function(name, window, pane)
    --     modal.set_right_status(window, name)
    --     -- 可选：把 mode 写进窗口标题
    --     -- modal.set_window_title(pane, name)
    -- end)

    -- wezterm.on("modal.exit", function(_, window, pane)
    --     window:set_right_status("")
    --     -- 可选：恢复标题
    --     -- modal.reset_window_title(pane)
    -- end)

    wezterm.on("update-right-status", function(window, pane)
        if modal.get_mode(window) then
            modal.set_right_status(window)
            return
        end
        window:set_right_status("") -- 你自己的默认 bar
    end)
end

return M
