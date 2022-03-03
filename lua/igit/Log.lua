local M = require 'igit.Class'()
local git = require('igit.git')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {},
        args = {'--oneline', '--branches', '--graph', '--decorate=short'},
        auto_reload = false
    }, options)
    self.buffers = require('igit.BufferManager')({type = 'log'})
end

function M:parse_line()
    local line = vim.fn.getline('.')
    local res = {}
    res.sha = line:find_str('([a-f0-9]+)%s')
    res.branches = vim.tbl_filter(function(e)
        return e ~= '->' and e ~= 'main'
    end, line:find_str('%((.*)%)$'):split())
    res.author = line:find_str('%s(<.->)%s')
    return res
end

function M:open()
    self.buffers:open({
        vcs_root = git.find_root(),
        mappings = self.options.mapping,
        auto_reload = self.options.auto_reload,
        reload_fn = function() return git.log(self.options.args) end
    })
end

return M
