local M = {}
local git = require('igit.git')
local page = require('igit.page')
local vutils = require('igit.vutils')

function M.setup(options)
    M.options = M.options or
                    {mapping = {n = {['<cr>'] = M.switch}}, args = {'-v'}}
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
    vutils.jobstart(git.checkout(M.parse_line().branch),
                    {post_exit = function() page.current():reload() end})
end

function M.open()
    local git_root = git.find_root()
    if git_root then
        page:get_or_new({
            vcs_root = git_root,
            filetype = 'branch',
            mappings = M.options.mapping,
            auto_reload = true,
            reload_fn = function() return git.branch(M.options.args) end
        })
    end
end

return M
