local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')

function M.setup(options)
    M.options = M.options or {
        mapping = {},
        args = {'--branches', '--graph'},
        pretty = 'format:"%h %s %cr <%an> %d"'
    }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.switch() end

function M.reload_fn()
    return git.log(table.concat(M.options.args, ' '),
                   '--pretty=' .. M.options.pretty)
end

function M.open()
    local git_root = git.find_root()
    if git_root then
        Vbuffer.get_or_new(git_root, 'log', M.options.mapping, M.reload_fn)
    end
end

return M
