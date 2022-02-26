local M = {}
local utils = require('igit.utils')

function M.Git(cmd)
    local git_dir = vim.b.vcs_root or M.find_root()
    return git_dir and ('git -C %s %s'):format(git_dir, cmd) or nil
end

function M.find_root() return vim.b.vcs_root or utils.find_directory('.git') end

local meta = {
    __index = function(_, cmd)
        local git_cmd = M.Git(('%s'):format(cmd))
        if git_cmd then
            return function(...)
                local args = {}
                for _, v in ipairs({...}) do
                    if vim.tbl_islist(v) then
                        vim.list_extend(args, v)
                    else
                        args[#args + 1] = v
                    end
                end
                return ('%s %s'):format(git_cmd, table.concat(args, ' '))
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
