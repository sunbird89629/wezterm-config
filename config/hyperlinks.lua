local wezterm = require('wezterm')

local M = {}

function M.setup(config)
   local rules = wezterm.default_hyperlink_rules()

   -- 1. VSCode 文件跳转规则
   -- 匹配绝对路径: /path/to/file.lua:10:5 或 /path/to/file.lua:10
   table.insert(rules, {
      regex = [=[(?:\s|^)(/[^:\s\(\)\[\]\{\}]+):(\d+)(?::(\d+))?]=],
      format = 'vscode://file$1:$2:$3',
   })

   -- 2. VSCode 相对路径跳转 (针对 ./ 或 ../ 开头的路径)
   table.insert(rules, {
      regex = [=[\b(\.\.?/[^:\s\(\)\[\]\{\}]+):(\d+)(?::(\d+))?\b]=],
      format = 'vscode://file$1:$2:$3',
   })

   -- 3. 处理被各种括号包裹的 URL
   -- (URL)
   table.insert(rules, {
      regex = [=[\((\w+://\S+)\)]=],
      format = '$1',
      highlight = 1,
   })
   -- [URL]
   table.insert(rules, {
      regex = [=[\[(\w+://\S+)\]]=],
      format = '$1',
      highlight = 1,
   })
   -- {URL}
   table.insert(rules, {
      regex = [=[\{(\w+://\S+)\}]=],
      format = '$1',
      highlight = 1,
   })
   -- <URL>
   table.insert(rules, {
      regex = [=[<(\w+://\S+)>]=],
      format = '$1',
      highlight = 1,
   })

   -- 4. 隐式邮件地址
   table.insert(rules, {
      regex = [=[\b\w+@[\w-]+(\.[\w-]+)+\b]=],
      format = 'mailto:$0',
   })

   config.hyperlink_rules = rules
end

return M
