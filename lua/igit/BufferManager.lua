local M = require 'igit.Class'()
local utils = require('igit.utils')
local Buffer = require('igit.Buffer')
local global = require('igit.global')
local git = require('igit.git')

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
    vim.cmd(('tab drop %s'):format(filename))
    opts.id = vim.api.nvim_get_current_buf()

    if global.buffers[opts.id] == nil then
        opts.id = opts.id or vim.api.nvim_get_current_buf()
        opts.filetype = 'igit-' .. self.type
        opts.filename = filename
        global.buffers[opts.id] = Buffer(opts)
        git.ping_root_to_buffer(opts.vcs_root)

        vim.cmd(
            ('autocmd BufDelete <buffer> ++once lua require"igit.global".buffers[%d]=nil'):format(
                opts.id))
        if opts.auto_reload then
            vim.cmd(
                ('autocmd BufEnter <buffer> lua require"igit.global".buffers[%d]:reload()'):format(
                    opts.id))
        end
    end
    return global.buffers[opts.id]
end

function M:current()
    local id = vim.api.nvim_get_current_buf()
    return global.buffers[id]
end

return M
