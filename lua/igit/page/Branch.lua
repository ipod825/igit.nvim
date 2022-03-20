local M = require 'igit.page.Page':EXTEND()
local git = require('igit.git.git')
local vimfn = require('igit.libp.vimfn')
local term_utils = require('igit.libp.terminal_utils')
local job = require('igit.libp.job')
local Iterator = require('igit.libp.datatype.Iterator')
local Set = require('igit.libp.datatype.Set')
local a = require('igit.libp.async.async')
local Buffer = require('igit.libp.ui.Buffer')
local Grid = require('igit.libp.ui.Grid')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {
            n = {
                ['<cr>'] = self:BIND(self.switch),
                ['i'] = self:BIND(self.rename),
                ['m'] = self:BIND(self.mark),
                ['r'] = self:BIND(self.rebase),
                ['o'] = self:BIND(self.new_branch),
                ['X'] = self:BIND(self.force_delete_branch),
                ['s'] = self:BIND(self.show)
            },
            v = {
                ['r'] = self:BIND(self.rebase),
                ['X'] = self:BIND(self.force_delete_branch)
            }
        },
        args = {'-v'}
    }, options.branch or {})
end

function M:rename()
    self:current_buf():edit({
        get_items = function()
            return self:get_branches_in_rows(1, vim.fn.line('$'))
        end,
        update = function(ori_items, new_items)
            if #ori_items ~= #new_items then
                vim.notify("Can't remove or add items!")
                return
            end
            for i = 1, #ori_items do
                local intermediate = ('%s-igitrename'):format(ori_items[i])
                job.run(('git branch -m %s %s'):format(ori_items[i],
                                                       intermediate))
            end
            for i = 1, #ori_items do
                local intermediate = ('%s-igitrename'):format(ori_items[i])
                job.run(('git branch -m %s %s'):format(intermediate,
                                                       new_items[i]))
            end
        end
    })
end

function M:mark() self:current_buf()
    :mark({branch = self:parse_line().branch}, 2) end

function M:show()
    local branch = self:parse_line().branch
    local grid = Grid()
    grid:add_row(1):fill_column(Buffer({content = {branch}}))
    grid:add_row():fill_column(Buffer({
        bo = {filetype = 'igit'},
        content = function() return git.show('%s'):format(branch) end
    })):set_lead()
    grid:show()
end

function M:rebase()
    local ori_branch = job.popen(git.branch('--show-current'))
    local anchor = self:get_anchor_branch()
    local base_branch, grafted_ancestor = anchor.base,
                                          anchor.grafted_ancestor or ''
    local branches = self:get_branches_in_rows(vimfn.visual_rows())

    local current_buf = self:current_buf()
    a.sync(function()
        for new_branch in branches:values() do
            local next_grafted_ancestor =
                ('%s_original_conflicted_with_%s_created_by_igit'):format(
                    new_branch, base_branch)
            a.wait(job.run_async(git.branch(
                                     ('%s %s'):format(next_grafted_ancestor,
                                                      new_branch))))
            if grafted_ancestor ~= '' then
                local succ = 0 ==
                                 a.wait(job.run_async(
                                            git.rebase(
                                                ('--onto %s %s %s'):format(
                                                    base_branch,
                                                    grafted_ancestor, new_branch))))
                if grafted_ancestor:endswith('created_by_igit') then
                    a.wait(job.run_async(git.branch('-D ' .. grafted_ancestor)))
                end
                if not succ then
                    current_buf:reload()
                    return
                end
            else
                if 0 ~=
                    a.wait(job.run_async(
                               git.rebase(
                                   ('%s %s'):format(base_branch, new_branch)))) then
                    a.wait(job.run_async(
                               git.branch('-D ' .. next_grafted_ancestor)))
                    current_buf:reload()
                    return
                end
            end
            grafted_ancestor = next_grafted_ancestor
            base_branch = new_branch
        end
        a.wait(job.run_async(git.branch('-D ' .. grafted_ancestor)))
        a.wait(job.run_async(git.checkout(ori_branch)))
        current_buf:reload()
    end)()
end

function M:parse_line(linenr)
    linenr = linenr or '.'
    local line = term_utils.remove_ansi_escape(vim.fn.getline(linenr))
    local res = {is_current = false, branch = nil}
    res.is_current = line:find_str('%s*(%*?)') ~= ''
    res.branch = line:find_str('%s?([^%s%*]+)%s?')
    return res
end

function M:switch()
    self:runasync_and_reload(git.checkout(self:parse_line().branch))
end

function M:get_anchor_branch()
    local mark = self:current_buf().ctx.mark
    return {
        base = mark and mark[1].branch or
            job.popen(git.branch('--show-current')),
        grafted_ancestor = mark and mark[2] and mark[2].branch
    }
end

function M:get_branches_in_rows(row_beg, row_end)
    return Iterator.range(row_beg, row_end):map(
               function(e) return self:parse_line(e).branch end):collect()
end

function M:new_branch()
    local base_branch = self:get_anchor_branch().base
    self:current_buf():edit({
        get_items = function()
            return Set(self:get_branches_in_rows(vimfn.all_rows()))
        end,
        update = function(ori_branches, new_branches)
            for new_branch in (new_branches - ori_branches):values() do
                job.run(git.checkout(
                            ('-b %s %s'):format(new_branch, base_branch)))
            end
        end
    })
    vim.cmd('normal! o')
    vim.cmd('startinsert')
end

function M:force_delete_branch()
    local cmds = self:get_branches_in_rows(vimfn.visual_rows()):map(
                     function(b) return git.branch('-D ' .. b) end):collect()
    self:runasync_all_and_reload(cmds)
end

function M:open(args)
    args = args or self.options.args
    self:open_or_new_buffer(args, {
        vcs_root = git.find_root(),
        type = 'branch',
        mappings = self.options.mapping,
        buf_enter_reload = true,
        content = function() return git.branch(args) end
    })
end

return M
