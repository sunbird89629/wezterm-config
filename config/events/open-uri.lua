local wezterm = require('wezterm')

local function setup()
   wezterm.on('open-uri', function(window, pane, uri)
      if not uri:match('^wezterm%-open://') then
         return  -- 让 WezTerm 默认处理其他 URI
      end

      -- 去掉协议头，再去掉末尾多余的冒号（空 capture group 会产生 "::"）
      local raw = uri:gsub('^wezterm%-open://', ''):gsub(':+$', '')

      -- 解析 path:line:col 或 path:line 或 path
      local file, line, col = raw:match('^(.-):(%d+):(%d+)$')
      if not file then
         file, line = raw:match('^(.-):(%d+)$')
      end
      if not file then
         file = raw
      end

      -- 相对路径用 pane 的 CWD 补全
      local full_path
      if file:sub(1, 1) == '/' then
         full_path = file
      else
         local cwd_obj = pane:get_current_working_dir()
         local cwd = cwd_obj and cwd_obj.file_path or os.getenv('HOME')
         -- file_path 可能带 trailing slash
         cwd = cwd:gsub('/$', '')
         full_path = cwd .. '/' .. file
      end

      local vscode_uri
      if line and col then
         vscode_uri = 'vscode://file' .. full_path .. ':' .. line .. ':' .. col
      elseif line then
         vscode_uri = 'vscode://file' .. full_path .. ':' .. line
      else
         vscode_uri = 'vscode://file' .. full_path
      end

      wezterm.open_with(vscode_uri)
      return true  -- 阻止默认行为
   end)
end

return { setup = setup }
