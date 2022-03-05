local M = {}
local utils = require('igit.utils.utils')
local job = require('igit.vim_wrapper.job')
local List = require('igit.datatype.List')

-- A version that allows setting git_dir. Useful when find_root fails (for e.g.
-- when closing a buffer).
function M.rawcmd(cmd, opts)
    opts = opts or {}
    vim.validate({
        cmd = {cmd, 'string'},
        git_dir = {opts.git_dir, 'string', true}
    })
    local git_dir = opts.git_dir or vim.b.vcs_root or M.find_root()
    return git_dir and
               ('git --no-pager -c color.ui=always -C %s %s'):format(git_dir,
                                                                     cmd) or nil
end

function M.Git(cmd)
    local git_dir = vim.b.vcs_root or M.find_root()
    return git_dir and
               ('git --no-pager -c color.ui=always -C %s %s'):format(git_dir,
                                                                     cmd) or nil
end

function M.find_root() return vim.b.vcs_root or utils.find_directory('.git') end

function M.commit_message_file_path()
    return ('%s/.git/COMMIT_EDITMSG'):format(M.find_root())
end

function M.status_porcelain()
    local res = {}
    for line in job.popen(M.status('--porcelain'), true):iter() do
        local state, old_filename, _, new_filename = unpack(line:split())
        res[old_filename] = {
            index = state:sub(1, 1),
            worktree = state:sub(2, 2)
        }
        if new_filename then
            res[new_filename] = {
                index = state:sub(1, 1),
                worktree = state:sub(2, 2)
            }
        end
    end
    return res
end

setmetatable(M, {
    __index = function(_, cmd)
        local git_cmd = M.Git(cmd)
        if git_cmd then
            return function(...)
                local args = List()
                for e in List({...}):iter() do
                    if vim.tbl_islist(e) then
                        args:extend(e)
                    else
                        args:append(e)
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
})

return M
