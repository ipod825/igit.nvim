local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')

function M.setup(options)
    M.options = M.options or {mapping = {}, args = {}}
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.parse_line() end

function M.open()
    local git_root = git.find_root()
    if git_root then
        Vbuffer.get_or_new({
            vcs_root = git_root,
            filetype = 'status',
            mappings = M.options.mapping,
            reload_fn = function() return git.status(M.options.args) end

        })
    end
end

return M
