local M = {}
local git = require('igit.git')
local page = require('igit.page')
local utils = require('igit.utils')
local vutils = require('igit.vutils')
local itertools = require('igit.itertools')

function M.setup(options)
    M.options = M.options or {
        mapping = {
            n = {
                ['<cr>'] = M.switch,
                ['i'] = M.rename,
                ['m'] = M.mark,
                ['r'] = M.rebase_onto,
                ['o'] = M.new_branch,
                ['X'] = M.force_delete_branch
            },
            v = {['r'] = M.rebase_onto, ['X'] = M.force_delete_branch}
        },
        args = {'-v'}
    }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.rename()
    page.current():edit({
        get_items = function()
            return M.get_branches_in_rows(1, vim.fn.line('$'))
        end,
        update = function(ori_items, new_items)
            if #ori_items ~= #new_items then
                vim.notify("Can't remove or add items!")
                return
            end
            for i = 1, #ori_items do
                local intermediate = ('%s-igitrename'):format(ori_items[i])
                vutils.jobsyncstart(('git branch -m %s %s'):format(ori_items[i],
                                                                   intermediate))
            end
            for i = 1, #ori_items do
                local intermediate = ('%s-igitrename'):format(ori_items[i])
                vutils.jobsyncstart(('git branch -m %s %s'):format(intermediate,
                                                                   new_items[i]))
            end
        end
    })
end

function M.mark() page.current():mark({branch = M.parse_line().branch}) end

function M.rebase_onto()
    local base_branch = page.current():get_mark_ctx().branch

    local range = vutils.visual_range()
    local branches = M.get_branches_in_rows(range.row_beg, range.row_end)

    local prev_new_branch_backup = ''
    for _, new_branch in ipairs(branches) do
        vutils.jobsyncstart(git.checkout(new_branch))
        local new_backup = ('%s_backup'):format(new_branch)
        vutils.jobsyncstart(git.branch(new_backup))
        if #prev_new_branch_backup > 0 then
            vutils.jobsyncstart(git.rebase(
                                    ('--onto %s %s %s'):format(base_branch,
                                                               prev_new_branch_backup,
                                                               new_branch)))
            vutils.jobsyncstart(git.branch('-D ' .. prev_new_branch_backup))
        else
            vutils.jobsyncstart(git.rebase(('%s'):format(base_branch)))
        end
        prev_new_branch_backup = new_backup
        base_branch = new_branch
    end
    vutils.jobsyncstart(git.branch('-D ' .. prev_new_branch_backup))
    page.current():reload()
end

function M.parse_line(linenr)
    linenr = linenr or '.'
    local line = vim.fn.getline(linenr)
    local res = {is_current = false, branch = nil}
    res.is_current = line:find_str('%s*(%*?)') ~= ''
    res.branch = line:find_str('%s?([^%s%*]+)%s?'):gsub('%c+%[[%d;]*m', '')
    return res
end

function M.switch()
    vutils.jobstart(git.checkout(M.parse_line().branch),
                    {post_exit = function() page.current():reload() end})
end

function M.get_marked_or_current_branch()
    local marked = page.current():get_mark_ctx()
    return marked and marked.branch or
               vutils.pipesync(git.branch('--show-current'))
end

function M.get_branches_in_rows(row_beg, row_end)
    return itertools.range(row_beg, row_end):map(M.parse_line):map(
               function(e) return e.branch end):collect()
end

function M.new_branch()
    local base_branch = M.get_marked_or_current_branch()
    page.current():edit({
        get_items = function()
            return utils.set(M.get_branches_in_rows(1, vim.fn.line('$')))
        end,
        update = function(ori_branches, new_branches)
            for new_branch, _ in pairs(new_branches) do
                if ori_branches[new_branch] == nil then
                    vutils.pipesync(git.checkout(
                                        ('-b %s %s'):format(new_branch,
                                                            base_branch)))
                end
            end
        end
    })
    vim.cmd('normal! o')
    vim.cmd('startinsert')
end

function M.force_delete_branch()
    local range = vutils.visual_range()
    for _, branch in
        ipairs(M.get_branches_in_rows(range.row_beg, range.row_end)) do
        vutils.pipesync(git.branch('-D ' .. branch))
    end
    page.current():reload()
end

function M.open()
    local git_root = git.find_root()
    if git_root then
        page:get_or_new({
            vcs_root = git_root,
            filetype = 'branch',
            mappings = M.options.mapping,
            auto_reload = true,
            reload_fn = function() return git.branch(M.options.args) end
        })
    end
end

return M
