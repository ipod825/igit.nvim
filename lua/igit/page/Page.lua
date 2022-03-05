local M = require('igit.datatype.Class')()
local utils = require('igit.utils.utils')
local vutils = require('igit.vim_wrapper.vutils')
local Buffer = require('igit.vim_wrapper.Buffer')
local global = require('igit.global')

function M:open_buffer(opts)
    if opts.vcs_root == nil or opts.vcs_root == '' then
        vim.notify('No git project found!')
        return
    end
    vim.validate({
        vcs_root = {opts.vcs_root, 'string'},
        type = {opts.type, 'string'},
        auto_reload = {opts.auto_reload, 'boolean'},
        mappings = {opts.mappings, 'table'},
        reload_fn = {opts.reload_fn, 'function'},
        bo = {opts.bo, 'boolean', true}
    })

    vutils.open_buffer_and_ping_vcs_root('tab drop', opts.vcs_root,
                                         ('igit://%s-%s'):format(
                                             utils.basename(opts.vcs_root),
                                             opts.type))
    local id = vim.api.nvim_get_current_buf()

    global.buffers = global.buffers or {}
    if global.buffers[id] == nil then
        global.buffers[id] = Buffer({
            mappings = opts.mappings,
            reload_fn = opts.reload_fn,
            auto_reload = opts.auto_reload,
            bo = vim.tbl_extend('force', {
                filetype = 'igit-' .. opts.type,
                bufhidden = 'hide',
                buftype = 'nofile',
                modifiable = false
            }, opts.bo or {})
        })

    end
    return global.buffers[id]
end

function M:buffer()
    local id = vim.api.nvim_get_current_buf()
    return global.buffers[id]
end

return M
