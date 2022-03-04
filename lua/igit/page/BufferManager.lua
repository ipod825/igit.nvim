local M = require 'igit.datatype.Class'()
local utils = require('igit.utils.utils')
local vutils = require('igit.vim_wrapper.vutils')
local Buffer = require('igit.vim_wrapper.Buffer')
local global = require('igit.global')
local git = require('igit.git.git')

function M:init(opts)
    vim.validate({type = {opts.type, 'string'}})
    global.buffers = global.buffers or {}
    self.type = opts.type
end

function M:open(opts)
    if opts.vcs_root == nil or opts.vcs_root == '' then
        vim.notify('No git project found!')
        return
    end
    vim.validate({
        vcs_root = {opts.vcs_root, 'string'},
        auto_reload = {opts.auto_reload, 'boolean', true}
    })
    local filename = ('%s-%s'):format(utils.basename(opts.vcs_root), self.type)

    vutils.open_buffer_and_ping_vcs_root('tab drop', opts.vcs_root,
                                         ('igit://%s'):format(filename))
    opts.id = vim.api.nvim_get_current_buf()

    if global.buffers[opts.id] == nil then
        opts.id = opts.id or vim.api.nvim_get_current_buf()
        opts.filetype = 'igit-' .. self.type
        opts.filename = filename
        global.buffers[opts.id] = Buffer(opts)

        vim.cmd(
            ('autocmd BufDelete <buffer> ++once lua require"igit.global".buffers[%d]=nil'):format(
                opts.id))
        if opts.auto_reload then
            vim.cmd(
                ('autocmd BufEnter <buffer> lua require"igit.global".buffers[%d]:reload()'):format(
                    opts.id))
        end
        -- only reload on creation. Other reload is triggered by autocmd.
        global.buffers[opts.id]:reload()
    end
    return global.buffers[opts.id]
end

function M:current()
    local id = vim.api.nvim_get_current_buf()
    return global.buffers[id]
end

return M
