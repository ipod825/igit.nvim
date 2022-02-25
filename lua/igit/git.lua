local M = {}
local utils = require('igit.utils')

function M.Git(cmd)
    local git_dir = vim.b.vcs_root or M.find_root()
    return git_dir and string.format('git -C %s %s', git_dir, cmd) or nil
end

function M.find_root() return vim.b.vcs_root or utils.find_directory('.git') end

local meta = {
    __index = function(_, cmd)
        local git_cmd = M.Git(string.format('%s', cmd))
        if git_cmd then
            return function(...)
                return string.format('%s %s', git_cmd, table.concat({...}, ' '))
            end
        end

        return function()
            vim.notify('Not a git directory')
            return ''
        end
    end
}

setmetatable(M, meta)

return M
