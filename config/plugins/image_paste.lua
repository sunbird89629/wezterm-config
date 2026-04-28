local wezterm = require("wezterm")
local process = require("utils.process")

local M = {}

-- 专门为 macOS 优化的图片保存函数
local function save_mac_image()
    local tmp_dir = os.getenv("HOME") .. "/.gemini/tmp/images"
    wezterm.run_child_process({"mkdir", "-p", tmp_dir})
    
    local filepath = tmp_dir .. "/paste_" .. os.date("%Y%m%d_%H%M%S") .. ".png"

    -- 使用 AppleScript 检查剪贴板并保存 PNG
    -- class PNGf 是 macOS 剪贴板中标准的 PNG 数据标识
    local script = [[
        try
            set imagePath to "]] .. filepath .. [["
            set imageFile to open for access POSIX file imagePath with write permission
            set theData to the clipboard as «class PNGf»
            write theData to imageFile
            close access imageFile
            return "ok"
        on error
            return "no_image"
        end try
    ]]
    
    local success, stdout, _ = wezterm.run_child_process({"osascript", "-e", script})
    
    if success and stdout:find("ok") then
        return filepath
    end
    return nil
end

function M.smart_paste(window, pane)
    -- 1. 尝试保存图片
    local image_path = save_mac_image()
    
    if image_path then
        if process.foreground_matches(pane, { "claude", "gemini", "node" }) then
            pane:send_text(image_path .. "\n")
            window:toast_notification("AI 助手", "已自动上传截图", nil, 2000)
        else
            pane:send_text(image_path)
        end
    else
        -- 2. 如果剪贴板不是图片，则执行标准粘贴动作
        window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane)
    end
end

return M
