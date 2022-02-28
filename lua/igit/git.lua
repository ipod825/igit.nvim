local M = {}
local utils = require('igit.utils')
local vutils = require('igit.vutils')

function M.Git(cmd)
    local git_dir = vim.b.vcs_root or M.find_root()
    return
        git_dir and ('git -c color.ui=always -C %s %s'):format(git_dir, cmd) or
            nil
end

function M.ping_root_to_buffer() vim.b.vcs_root = M.find_root() end

function M.find_root()
    return vim.b.vcs_root or utils.find_directory('.git') or
               utils.find_directory('.git', vim.fn.getcwd())
end

function M.commit_message_file_path()
    return ('%s/.git/COMMIT_EDITMSG'):format(M.find_root())
end

function M.file_check_sum(path)
    return vim.fn.system('git hash-object ' .. path):trim()
end

function M.status_porcelain()
    local lines = {}
    vutils.jobsyncstart(M.status('--porcelain'), {
        stdout_flush = function(new_lines)
            vim.list_extend(lines, new_lines)
        end
    })

    local res = {}
    for _, line in ipairs(lines) do
        for state, filename in line:gmatch('(%s*[^%s]+)%s+([^%s]+)') do
            res[filename] = {
                index = state:sub(1, 1),
                worktree = state:sub(2, 2)
            }
            break
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
