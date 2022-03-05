local M = require('igit.page.Page')()
local git = require('igit.git.git')
local global = require('igit.global')
local utils = require('igit.utils.utils')
local job = require('igit.vim_wrapper.job')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {n = {['<cr>'] = self:bind(self.switch)}},
        args = {'--oneline', '--branches', '--graph', '--decorate=short'},
        auto_reload = false
    }, options)
end

function M:switch()
    self:select_branch(self:parse_line().branches,
                       function(branch) job.run(git.checkout(branch)) end)
end

function M:select_branch(branches, callback)
    if #branches == 1 then
        callback(branches[1])
        return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
        style = "minimal",
        relative = 'editor',
        row = 3,
        col = 3,
        width = 20,
        height = 6,
        border = 'single'
    })
    global.callbacks = global.callbacks or {}
    global.callbacks[buf] = function(e)
        vim.cmd('quit')
        callback(e)
        global.callbacks[buf] = nil
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, branches)
    vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>',
                                ('<cmd>lua require"igit.global".callbacks[%d](vim.fn.getline("."))<cr>'):format(
                                    buf), {noremap = true})
end

function M:parse_line()
    local line = vim.fn.getline('.')
    local res = {}
    res.sha = line:find_str('([a-f0-9]+)%s')
    res.branches = vim.tbl_filter(function(e)
        return e ~= '->' and e ~= 'main'
    end, utils.remove_ansi_escape(line:find_str('%((.*)%)')):split('%s,'))
    res.author = line:find_str('%s(<.->)%s')
    return res
end

function M:open(args)
    args = args or self.options.args
    self:open_or_new_buffer(args, {
        vcs_root = git.find_root(),
        type = 'log',
        mappings = self.options.mapping,
        auto_reload = self.options.auto_reload,
        reload_cmd_gen_fn = function() return git.log(args) end
    })
end

return M
