local wezterm = require("wezterm")
local M = {}
local act = wezterm.action;

function M.setup(config)
    -- 确保 config.keys 表存在
    config.keys = config.keys or {}

    -- table.insert(config.keys, {
    --   key = "e",
    --   mods = "CMD|SHIFT",
    --   action = wezterm.action.InputSelector({
    --     title = "Demo Selection Box",
    --     choices = {
    --       { label = "Option 1 (opt1)", id = "opt1" },
    --       { label = "Option 2 (opt2)", id = "opt2" },
    --       { label = "Hello World (hello)", id = "hello" },
    --     },
    --     action = wezterm.action_callback(function(window, pane, id, label)
    --       if not id and not label then
    --         wezterm.log_info("Demo Menu: User cancelled")
    --       else
    --         wezterm.log_info("Demo Menu: User selected " .. label .. " (id: " .. id .. ")")
    --         window:toast_notification("Selection", "You chose: " .. label, nil, 4000)
    --       end
    --     end),
    --   }),
    -- })
    table.insert(config.keys, {
        key = 'E',
        mods = 'CMD|SHIFT',
        action = act.InputSelector {
            action = wezterm.action_callback(function(window, pane, id, label)
                if not id and not label then
                    wezterm.log_info 'cancelled'
                else
                    wezterm.log_info('you selected ', id, label)
                    pane:send_text(id)
                end
            end),
            title = 'I am title',
            choices = { -- This is the first entry
            {
                -- Here we're using wezterm.format to color the text.
                -- You can just use a string directly if you don't want
                -- to control the colors
                label = wezterm.format {{
                    Foreground = {
                        AnsiColor = 'Red'
                    }
                }, {
                    Text = 'No'
                }, {
                    Foreground = {
                        AnsiColor = 'Green'
                    }
                }, {
                    Text = ' thanks'
                }},
                -- This is the text that we'll send to the terminal when
                -- this entry is selected
                id = 'Regretfully, I decline this offer.'
            }, -- This is the second entry
            {
                label = 'WTF?',
                id = 'An interesting idea, but I have some questions about it.'
            }, -- This is the third entry
            {
                label = 'LGTM',
                id = 'This sounds like the right choice'
            }}
        }
    })
end

return M
