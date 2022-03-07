local M = require('igit.lib.datatype.Class')()
local path = require('igit.lib.path')
local Buffer = require('igit.vim_wrapper.Buffer')
local Set = require('igit.lib.datatype.Set')
local job = require('igit.lib.job')
local a = require('igit.lib.async.async')

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
        bo = {
            filetype = 'igit-' .. opts.type,
            bufhidden = 'hide',
            buftype = 'nofile',
            modifiable = false
        }
    }, opts)

    return Buffer.open_or_new(opts)
end

function M:current_buf() return Buffer.get_current_buffer() end

function M:runasync_and_reload(cmd)
    local current_buf = self:current_buf()
    a.sync(function()
        a.wait(job.run_async(cmd))
        current_buf:reload()
    end)()
end

function M:runasync_all_and_reload(cmds)
    local current_buf = self:current_buf()
    a.sync(function()
        a.wait(job.runasync_all(cmds))
        current_buf:reload()
    end)()
end

return M
