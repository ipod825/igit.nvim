local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')

function M.setup(options)
    M.options = M.options or {mapping = {['<cr>'] = M.switch}}
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
    vim.fn.jobstart(git.checkout(M.parse_line().branch),
                    {on_exit = function() Vbuffer.current():reload() end})
end

function M.open()
    local git_root = git.find_root()
    if git_root then
        Vbuffer.get_or_new(git_root, 'branch', M.options.mapping, git.branch)
    end
end

return M
