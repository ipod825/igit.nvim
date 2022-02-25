local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')
local utils = require('igit.utils')

function M.setup(options)
    M.options = M.options or {mapping = {['<cr>'] = M.switch}, args = {'-v'}}
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.parse_line()
    local res = {is_current = false, branch = nil}
    local line = vim.fn.getline('.')
    res.is_current = line:find_str('%s*(%*?)') ~= ''
    res.branch = line:find_str('%s([^%s].-)%s*$')
    return res
end

function M.switch()
    local jhandles = utils.job_handles({
        post_exit = function() Vbuffer.current():reload() end
    })

    vim.fn.jobstart(git.checkout(M.parse_line().branch), {
        on_stderr = jhandles.on_stderr,
        on_exit = jhandles.on_exit
    })
end

function M.open()
    local git_root = git.find_root()
    if git_root then
        Vbuffer.get_or_new({
            vcs_root = git_root,
            filetype = 'branch',
            mappings = M.options.mapping,
            reload_fn = function()
                return git.branch(table.concat(M.options.args, ' '))
            end
        })
    end
end

return M
