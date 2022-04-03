local M = {}
local path = require('igit.libp.path')
local job = require('igit.libp.job')
local List = require('igit.libp.datatype.List')
local log = require('igit.log')

local arg_strcat_factory = function(git_cmd)
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

local cmd_with_default_args = function(cmd, opts)
    opts = opts or {}
    vim.validate({
        git_dir = {opts.git_dir, 'string', true},
        no_color = {opts.no_color, 'boolean', true}
    })
    local git_dir = opts.git_dir or vim.b.vcs_root or M.find_root()
    local color_str = opts.no_color and '' or '-c color.ui=always'
    return git_dir and
               ('git --no-pager %s -C %s %s'):format(color_str, git_dir, cmd) or
               nil
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

function M.with_default_args(opts)
    return setmetatable({}, {
        __index = function(_, cmd)
            return arg_strcat_factory(cmd_with_default_args(cmd, opts))
        end
    })
end

setmetatable(M, {
    __index = function(_, cmd)
        return arg_strcat_factory(cmd_with_default_args(cmd))
    end
})

return M
