local M = require 'igit.datatype.Class'()
local git = require('igit.git.git')
local vutils = require('igit.vim_wrapper.vutils')
local job = require('igit.vim_wrapper.job')
local Iterator = require('igit.datatype.Iterator')
local Set = require('igit.datatype.Set')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {
            n = {
                ['<cr>'] = self:bind(self.switch),
                ['i'] = self:bind(self.rename),
                ['m'] = self:bind(self.mark),
                ['r'] = self:bind(self.rebase),
                ['o'] = self:bind(self.new_branch),
                ['X'] = self:bind(self.force_delete_branch)
            },
            v = {
                ['r'] = self:bind(self.rebase),
                ['X'] = self:bind(self.force_delete_branch)
            }
        },
        args = {'-v'}
    }, options)
    self.buffers = require('igit.page.BufferManager')({type = 'branch'})
end

function M:rename()
    self.buffers:current():edit({
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

function M:mark()
    self.buffers:current():mark({branch = self:parse_line().branch}, 2)
end

function M:rebase()
    local anchor = self:get_anchor_branch()
    local base_branch, grafted_ancestor = anchor.base,
                                          anchor.grafted_ancestor or ''
    local branches = self:get_branches_in_rows(vutils.visual_rows())

    for new_branch in branches:iter() do
        local next_grafted_ancestor =
            ('_%s_original_conflicted_with_%s'):format(new_branch, base_branch)
        job.run(git.branch(('%s %s'):format(next_grafted_ancestor, new_branch)))
        if grafted_ancestor ~= '' then
            local succ = 0 ==
                             job.run(git.rebase(
                                         ('--onto %s %s %s'):format(base_branch,
                                                                    grafted_ancestor,
                                                                    new_branch)))
            job.run(git.branch('-D ' .. grafted_ancestor))
            if not succ then
                self.buffers:current():reload()
                return
            end
        else
            if 0 ~=
                job.run(git.rebase(('%s %s'):format(base_branch, new_branch))) then
                job.run(git.branch('-D ' .. next_grafted_ancestor))
                self.buffers:current():reload()
                return
            end
        end
        grafted_ancestor = next_grafted_ancestor
        base_branch = new_branch
    end
    job.run(git.branch('-D ' .. grafted_ancestor))
    self.buffers:current():reload()
end

function M:parse_line(linenr)
    linenr = linenr or '.'
    local line = vim.fn.getline(linenr)
    local res = {is_current = false, branch = nil}
    res.is_current = line:find_str('%s*(%*?)') ~= ''
    res.branch = line:find_str('%s?([^%s%*]+)%s?'):gsub('%c+%[[%d;]*m', '')
    return res
end

function M:switch()
    job.runasync(git.checkout(self:parse_line().branch),
                 {post_exit = function() self.buffers:current():reload() end})
end

function M:get_anchor_branch()
    local mark = self.buffers:current().ctx.mark
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
    self.buffers:current():edit({
        get_items = function()
            return Set(self:get_branches_in_rows(vutils.all_rows()))
        end,
        update = function(ori_branches, new_branches)
            for new_branch in new_branches:iter() do
                if ori_branches[new_branch] == nil then
                    job.run(git.checkout(
                                ('-b %s %s'):format(new_branch, base_branch)))
                end
            end
        end
    })
    vim.cmd('normal! o')
    vim.cmd('startinsert')
end

function M:force_delete_branch()
    for branch in self:get_branches_in_rows(vutils.visual_rows()):iter() do
        job.run(git.branch('-D ' .. branch))
    end
    self.buffers:current():reload()
end

function M:open()
    self.buffers:open({
        vcs_root = git.find_root(),
        mappings = self.options.mapping,
        auto_reload = true,
        reload_fn = function() return git.branch(self.options.args) end
    })
end

return M
