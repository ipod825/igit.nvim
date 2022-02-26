local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')

function M.setup(options)
    M.options = M.options or {
        mapping = {},
        args = {'--branches', '--graph'},
        pretty = 'format:"%h %s %cr <%an> %d"',
        parse_line = M.parse_line,
        auto_reload = false
    }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.parse_line()
    local line = vim.fn.getline('.')
    local res = {}
    res.sha = line:find_str('([a-f0-9]+)%s')
    res.branches = vim.tbl_filter(function(e)
        return e ~= '->' and e ~= 'main'
    end, line:find_str('%((.*)%)$'):split())
    res.author = line:find_str('%s(<.->)%s')
    return res
end

function M.switch() end

function M.reload_fn()
    return git.log(table.concat(M.options.args, ' '),
                   '--pretty=' .. M.options.pretty)
end

function M.open()
    local git_root = git.find_root()
    if git_root then
        Vbuffer:get_or_new({
            vcs_root = git_root,
            filetype = 'log',
            mappings = M.options.mapping,
            auto_reload = M.options.auto_reload,
            reload_fn = function()
                return git.log(M.options.args, '--pretty=' .. M.options.pretty)
            end
        })
    end
end

return M
