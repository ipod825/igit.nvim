local M = {}
local path = require('igit.libp.path')
local job = require('igit.libp.job')
local List = require('igit.libp.datatype.List')
local log = require('igit.log')

local create_cmd_factory = function(git_cmd)
    if git_cmd then
        return function(...)
            local args = List()
            for e in List({...}):values() do
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

local gen_cmd_with_default_args = function(cmd, git_dir)
    git_dir = git_dir or vim.b.vcs_root or M.find_root()
    return git_dir and
               ('git --no-pager -c color.ui=always -C %s %s'):format(git_dir,
                                                                     cmd) or nil
end

function M.run_from(git_dir)
    vim.validate({git_cmd = {git_dir, 'string'}})
    return setmetatable({}, {
        __index = function(_, cmd)
            return create_cmd_factory(gen_cmd_with_default_args(cmd, git_dir))
        end
    })
end

function M.find_root()
    local res = vim.b.vcs_root or path.find_directory('.git')
    return res
end

function M.commit_message_file_path(git_dir)
    return ('%s/.git/COMMIT_EDITMSG'):format(git_dir)
end

function M.status_porcelain()
    local res = {}
    for line in job.popen(M.status('--porcelain'), true):values() do
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
        return create_cmd_factory(gen_cmd_with_default_args(cmd))
    end
})

return M
