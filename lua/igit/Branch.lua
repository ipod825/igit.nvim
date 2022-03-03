local M = require 'igit.Class'()
local git = require('igit.git')
local utils = require('igit.utils')
local vim_utils = require('igit.vim_utils')
local job = require('igit.job')
local itertools = require('igit.itertools')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {
            n = {
                ['<cr>'] = function() self:switch() end,
                ['i'] = function() self:rename() end,
                ['m'] = function() self:mark() end,
                ['r'] = function() self:rebase_onto() end,
                ['o'] = function() self:new_branch() end,
                ['X'] = function() self:force_delete_branc() end
            },
            v = {
                ['r'] = function() self:rebase_onto() end,
                ['X'] = function() self:force_delete_branch() end
            }
        },
        args = {'-v'}
    }, options)
    self.buffers = require('igit.BufferManager')({type = 'branch'})
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
    self.buffers:current():mark({branch = self:parse_line().branch})
end

function M:rebase_onto()
    local base_branch = self.buffers:current():get_mark_ctx().branch
    local branches = self:get_branches_in_rows(vim_utils.visual_rows())

    local prev_new_branch_backup = ''
    for _, new_branch in ipairs(branches) do
        job.run(git.checkout(new_branch))
        local new_backup = ('%s_backup'):format(new_branch)
        job.run(git.branch(new_backup))
        if #prev_new_branch_backup > 0 then
            job.run(git.rebase(('--onto %s %s %s'):format(base_branch,
                                                          prev_new_branch_backup,
                                                          new_branch)))
            job.run(git.branch('-D ' .. prev_new_branch_backup))
        else
            job.run(git.rebase(('%s'):format(base_branch)))
        end
        prev_new_branch_backup = new_backup
        base_branch = new_branch
    end
    job.run(git.branch('-D ' .. prev_new_branch_backup))
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

function M:get_marked_or_current_branch()
    local marked = self.buffers:current().ctx.mark or {}
    return marked.branch or job.popen(git.branch('--show-current'))
end

function M:get_branches_in_rows(row_beg, row_end)
    return itertools.range(row_beg, row_end):map(self.parse_line):map(
               function(e) return e.branch end):collect()
end

function M:new_branch()
    local base_branch = self:get_marked_or_current_branch()
    self.buffers:current():edit({
        get_items = function()
            return utils.set(self:get_branches_in_rows(vim_utils.all_rows()))
        end,
        update = function(ori_branches, new_branches)
            for new_branch, _ in pairs(new_branches) do
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
    for _, branch in ipairs(self:get_branches_in_rows(vim_utils.visual_rows())) do
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
