local M = require('igit.page.Page')()
local git = require('igit.git.git')
local job = require('igit.lib.job')
local List = require('igit.lib.datatype.List')
local nui = require('igit.nui.nui')
local Iterator = require('igit.lib.datatype.Iterator')
local term_utils = require('igit.lib.terminal_utils')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {
            n = {
                ['<cr>'] = self:bind(self.switch),
                ['m'] = self:bind(self.mark),
                ['r'] = self:bind(self.rebase)
            },
            v = {['r'] = self:bind(self.rebase)}
        },
        args = {'--oneline', '--branches', '--graph', '--decorate=short'},
        auto_reload = true
    }, options.log or {})
end

function M:switch()
    self:select_branch(self:parse_line().branches, 'Checkout', function(branch)
        self:runasync_and_reload(git.checkout(branch))
    end)
end

function M:mark()
    self:current_buf():mark({branch = self:parse_line().branches[1]}, 1)
end

function M:get_anchor_branch()
    local mark = self:current_buf().ctx.mark
    return {
        base = mark and mark[1].branch or
            job.popen(git.branch('--show-current'))
    }
end

function M:get_branches_in_rows(row_beg, row_end)
    return Iterator.range(row_beg, row_end):map(
               function(e) return self:parse_line(e).branches end):filter(
               function(e) return #e == 2 end):map(function(e) return e[0] end)
               :collect()
end

function M:rebase() end

function M:select_branch(branches, title, callback)
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

function M:parse_line(linenr)
    linenr = linenr or '.'
    local line = term_utils.remove_ansi_escape(vim.fn.getline(linenr))
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
        reload_cmd_gen_fn = function() return git.log(args) end,
        -- Log page can have too many lines, wiping it on hidden saves memory.
        bo = {bufhidden = 'wipe'}
    })
end

return M
