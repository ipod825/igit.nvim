local M = require('igit.page.Page')()
local git = require('igit.git.git')
local utils = require('igit.utils.utils')
local job = require('igit.vim_wrapper.job')
local List = require('igit.datatype.List')
local nui = require('igit.nui.nui')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {n = {['<cr>'] = self:bind(self.switch)}},
        args = {'--oneline', '--branches', '--graph', '--decorate=short'},
        auto_reload = true
    }, options)
end

function M:switch()
    self:select_branch(self:parse_line().branches, function(branch)
        job.run(git.checkout(branch))
        self:current_buf():reload()
    end, 'Checkout')
end

function M:select_branch(branches, callback, title)
    if #branches < 2 then return callback(branches[1]) end
    local popup_options = {
        relative = 'cursor',
        position = {row = 1, col = 0},
        border = {
            style = 'rounded',
            text = {
                top = ('[%s Commit]'):format(title or ''),
                top_align = 'center'
            }
        },
        win_options = {winhighlight = 'Normal:Normal'}
    }

    local menu = nui.Menu(popup_options, {
        lines = List(branches):map(nui.Menu.item):collect(),
        min_width = 20,
        keymap = {submit = {'<CR>', '<Space>'}},
        on_submit = function(item) callback(item.text) end
    })
    menu:mount()
    menu:on({nui.event.BufLeave}, function() menu:unmount() end, {once = true})
end

function M:parse_line()
    local line = utils.remove_ansi_escape(vim.fn.getline('.'))
    local res = {}
    res.sha = line:find_str('([a-f0-9]+)%s')
    local branch_candidates = line:find_str('%((.*)%)')
    res.branches = branch_candidates and
                       vim.tbl_filter(function(e)
            return e ~= '->' and e ~= 'HEAD'
        end, branch_candidates:split('%s,')) or {}
    table.insert(res.branches, res.sha)
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
