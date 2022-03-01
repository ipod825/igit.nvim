local M = {}
local git = require('igit.git')
local page = require('igit.page')
local vutils = require('igit.vutils')
local itertools = require('igit.itertools')

function M.setup(options)
    M.options = M.options or
                    {
            mapping = {n = {['<cr>'] = M.switch, ['i'] = M.rename}},
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
