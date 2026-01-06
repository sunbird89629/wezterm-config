local wezterm = require("wezterm")
local M = {}

function M.setup(config)
    config.ssh_domains = {{
        name = "router@office",
        remote_address = "192.168.1.1",
        username = "root",
        multiplexing = "None"
        -- multiplexing = "WezTerm"
    }, -- ssh -i ~/Downloads/ssh-key-2025-11-04.key ubuntu@129.146.130.13
    {
        name = "fanqiang@oracle",
        remote_address = "129.146.130.13",
        username = "ubuntu",
        multiplexing = "None",
        ssh_option = {
            identityfile = "~/.ssh/ssh-key-2025-11-04.key"
        }
        -- multiplexing = "WezTerm"
    }, {
        name = "hanguo@oracle",
        remote_address = "168.107.49.174",
        username = "ubuntu",
        multiplexing = "None",
        ssh_option = {
            identityfile = "~/.ssh/ssh-key-174.key"
        }
        -- multiplexing = "WezTerm"
    }, {
        name = "ceshi@oracle",
        remote_address = "137.131.60.151",
        username = "ubuntu",
        multiplexing = "None",
        ssh_option = {
            identityfile = "~/.ssh/ssh-key-2025-11-13.key"
        }
        -- multiplexing = "WezTerm"
    }}
end

return M

-- local platform = require('utils.platform')

-- local options = {
--    -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
--    ssh_domains = {},

--    -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
--    unix_domains = {},

--    -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
--    wsl_domains = {},
-- }

-- if platform.is_win then
--    options.ssh_domains = {
--       {
--          name = 'ssh:wsl',
--          remote_address = 'localhost',
--          multiplexing = 'None',
--          default_prog = { 'fish', '-l' },
--          assume_shell = 'Posix',
--       },
--    }

--    options.wsl_domains = {
--       {
--          name = 'wsl:ubuntu-fish',
--          distribution = 'Ubuntu',
--          username = 'kevin',
--          default_cwd = '/home/kevin',
--          default_prog = { 'fish', '-l' },
--       },
--       {
--          name = 'wsl:ubuntu-bash',
--          distribution = 'Ubuntu',
--          username = 'kevin',
--          default_cwd = '/home/kevin',
--          default_prog = { 'bash', '-l' },
--       },
--    }
-- end

-- return options
