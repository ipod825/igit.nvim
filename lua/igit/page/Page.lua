local M = require 'igit.libp.datatype.Class':EXTEND()
local path = require('igit.libp.path')
local Buffer = require('igit.libp.ui.Buffer')
local Set = require('igit.libp.datatype.Set')
local job = require('igit.libp.job')
local a = require('plenary.async')
local git = require('igit.git')
local log = require('igit.log')

function M:open_or_new_buffer(key, opts)
    if opts.vcs_root == nil or opts.vcs_root == '' then
        vim.notify('No git project found!')
        return
    end

    if type(key) == 'table' then key = table.concat(key, '') end

    vim.validate({
        key = {key, 'string'},
        vcs_root = {opts.vcs_root, 'string'},
        type = {opts.type, 'string'}
    })

    self.buffer_index = self.buffer_index or Set()
    local index = Set.size(self.buffer_index)
    Set.add(self.buffer_index, key, (index == 0) and '' or tostring(index))

    opts = vim.tbl_deep_extend('force', {
        open_cmd = 'tab drop',
        filename = ('igit://%s-%s%s'):format(path.basename(opts.vcs_root),
                                             opts.type, self.buffer_index[key]),
        b = {vcs_root = opts.vcs_root},
        bo = vim.tbl_extend('keep', opts.bo or {}, {
            filetype = 'igit-' .. opts.type,
            bufhidden = 'hide',
            buftype = 'nofile',
            modifiable = false
        })
    }, opts)

    local buffer = Buffer.open_or_new(opts)
    vim.cmd('lcd ' .. opts.vcs_root)
    return buffer
end

function M:current_buf() return Buffer.get_current_buffer() end

function M:runasync_and_reload(cmd)
    local current_buf = self:current_buf()
    a.void(function()
        job.run_async(cmd)
        current_buf:reload()
    end)()
end

function M:runasync_all_and_reload(cmds)
    local current_buf = self:current_buf()
    a.void(function()
        job.runasync_all(cmds)
        current_buf:reload()
    end)()
end

function M:rebase_branches(opts)
    vim.validate({
        branches = {opts.branches, 'table'},
        current_buf = {opts.current_buf, 'table'},
        grafted_ancestor = {opts.grafted_ancestor, 'string'},
        base_reference = {opts.base_reference, 'string'},
        ori_reference = {opts.ori_reference, 'string'}
    })

    log.warn(opts)

    local grafted_ancestor = opts.grafted_ancestor
    local base_branch = opts.base_reference
    a.void(function()
        for _, new_branch in ipairs(opts.branches) do
            local next_grafted_ancestor =
                ('%s_original_conflicted_with_%s_created_by_igit'):format(
                    new_branch, base_branch)
            job.run_async(git.branch(('%s %s'):format(next_grafted_ancestor,
                                                      new_branch)))
            if grafted_ancestor ~= '' then
                local succ = 0 ==
                                 job.run_async(
                                     git.rebase(
                                         ('--onto %s %s %s'):format(base_branch,
                                                                    grafted_ancestor,
                                                                    new_branch)))
                if grafted_ancestor:endswith('created_by_igit') then
                    job.run_async(git.branch('-D ' .. grafted_ancestor))
                end
                if not succ then
                    opts.current_buf:reload()
                    return
                end
            else
                if 0 ~=
                    job.run_async(git.rebase(
                                      ('%s %s'):format(base_branch, new_branch))) then
                    job.run_async(git.branch('-D ' .. next_grafted_ancestor))
                    opts.current_buf:reload()
                    return
                end
            end
            grafted_ancestor = next_grafted_ancestor
            base_branch = new_branch
        end
        job.run_async(git.branch('-D ' .. grafted_ancestor))
        job.run_async(git.checkout(opts.ori_reference))
        opts.current_buf:reload()
    end)()
end

return M
