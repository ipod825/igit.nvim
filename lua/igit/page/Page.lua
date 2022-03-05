local M = require('igit.datatype.Class')()
local utils = require('igit.utils.utils')
local Buffer = require('igit.vim_wrapper.Buffer')

function M:open_or_new_buffer(opts)
    if opts.vcs_root == nil or opts.vcs_root == '' then
        vim.notify('No git project found!')
        return
    end

    vim.validate({
        vcs_root = {opts.vcs_root, 'string'},
        type = {opts.type, 'string'}
    })
    opts = vim.tbl_deep_extend('force', {
        open_cmd = 'tab drop',
        filename = ('igit://%s-%s'):format(utils.basename(opts.vcs_root),
                                           opts.type),
        b = {vcs_root = opts.vcs_root}
    }, opts)

    return Buffer.open_or_new(opts)
end

return M
