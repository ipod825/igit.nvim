local M = {}
local utils = require('igit.utils')
local job = require('igit.job')

function M.Git(cmd)
    local git_dir = vim.b.vcs_root or M.find_root()
    return git_dir and
               ('git --no-pager -c color.ui=always -C %s %s'):format(git_dir,
                                                                     cmd) or nil
end

function M.ping_root_to_buffer(root) vim.b.vcs_root = root end

function M.find_root() return vim.b.vcs_root or utils.find_directory('.git') end

function M.commit_message_file_path()
    return ('%s/.git/COMMIT_EDITMSG'):format(M.find_root())
end

function M.file_check_sum(path)
    return vim.fn.system('git hash-object ' .. path):trim()
end

function M.status_porcelain()
    local res = {}
    for _, line in ipairs(job.popen(M.status('--porcelain'), true)) do
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
})

return M
