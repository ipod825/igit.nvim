local M = require('igit.page.Page')()
local git = require('igit.git.git')
local global = require('igit.global')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {n = {['<cr>'] = self:bind(self.switch)}},
        args = {'--oneline', '--branches', '--graph', '--decorate=short'},
        auto_reload = false
    }, options)
end

function M:switch()
    -- local cline_obj = self:parse_line()
    -- local branch 
end

function M:select_branch(branches)
    if #branches == 1 then return branches[1] end
    global.select_branch = coroutine.create(
                               function(selected_item)
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_open_win(buf, true, {
                relative = 'editor',
                width = math.floor(vim.fn.winwidth() / 3),
                height = math.floor(vim.fn.winheight() / 3),
                style = 'minimal',
                border = 'shadow'
            })
            vim.api.nvim_buf_set_lines(buf, 0, -1, branches)
            vim.cmd(
                'autocmd WinClosed <buffer> ++once lua coroutine.resume(require"igit.global".select_branch, 1)')
            coroutine.yield()
            return selected_item
        end)
    coroutine.resume(self.buffer.ctx.select_branch)
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
    self.buffer = self:open_or_new_buffer(
                      {
            vcs_root = git.find_root(),
            type = 'log',
            mappings = self.options.mapping,
            auto_reload = self.options.auto_reload,
            reload_fn = function() return git.log(self.options.args) end
        })
end

return M
