local M = {}
local git = require('igit.git')
local page = require('igit.page')
local vutils = require('igit.vutils')
local itertools = require('igit.itertools')

function M.setup(options)
    M.options = M.options or {
        mapping = {
            n = {
                ['<cr>'] = M.switch,
                ['i'] = M.rename,
                ['m'] = M.mark,
                ['r'] = M.rebase_onto
            },
            v = {['r'] = M.rebase_onto}
        },
        args = {'-v'}
    }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.rename()
    page.current():edit({
        get_items = function()
            return itertools.range(1, vim.fn.line('$')):map(M.parse_line):map(
                       function(e) return e.branch end):collect()
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
    local branches = itertools.range(range.row_beg, range.row_end):map(
                         M.parse_line):map(function(e) return e.branch end)
                         :collect()

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
    res.branch = line:find_str('%s([^%s]+)%s'):gsub('%c+%[[%d;]*m', '')
    return res
end

function M.switch()
    vutils.jobstart(git.checkout(M.parse_line().branch),
                    {post_exit = function() page.current():reload() end})
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
