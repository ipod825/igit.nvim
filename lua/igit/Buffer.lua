local M = require 'igit.Class'()
local vutils = require('igit.vutils')

function M:init(opts)
    vim.validate({
        id = {opts.id, 'number'},
        filetype = {opts.filetype, 'string'},
        mappings = {opts.mappings, 'table'},
        reload_fn = {opts.reload_fn, 'function'}
    })

    self.id = opts.id
    vim.bo.filetype = opts.filetype
    self.reload_fn = opts.reload_fn
    self.mappings = opts.mappings
    self:mapfn(opts.mappings)
    local ctx = {}
    self.ctx = setmetatable({}, {__index = ctx, __newindex = ctx})

    self.namespace = vim.api.nvim_create_namespace(opts.filename)

    vim.bo.modifiable = false
    vim.bo.bufhidden = 'hide'
    vim.bo.buftype = 'nofile'
    self:reload()
end

function M:mark(data)
    vim.api.nvim_buf_clear_namespace(self.id, self.namespace, 1, -1)
    self.ctx.mark = vim.tbl_extend('force', {}, data)
    vim.api.nvim_buf_add_highlight(self.id, self.namespace,
                                   'RedrawDebugRecompose', vim.fn.line('.') - 1,
                                   1, -1)
end

function M:save_edit()
    self.ctx.edit.update(self.ctx.edit.ori_items, self.ctx.edit.get_items())
    self.ctx.edit = nil
    vim.bo.buftype = 'nofile'
    vim.bo.modifiable = false
    self:mapfn(self.mappings)
    self:reload()
end

function M:edit(opts)
    vim.validate({
        get_items = {opts.get_items, 'function'},
        update = {opts.update, 'function'}
    })
    self.ctx.edit =
        vim.tbl_extend('force', {ori_items = opts.get_items()}, opts)
    vim.bo.buftype = 'acwrite'
    vim.cmd(
        ('autocmd BufWriteCmd <buffer> ++once lua require"igit.global".pages[%d]:save_edit()'):format(
            self.id))
    self:unmapfn(self.mappings)
    local ori_undo_levels = vim.o.undolevels
    vim.bo.undolevels = -1
    vim.bo.modifiable = true
    vim.cmd('substitute/\\e\\[[0-9;]*m//g')
    vim.bo.undolevels = ori_undo_levels
end

function M:mapfn(mappings)
    self.mapping_handles = self.mapping_handles or {}
    for mode, mode_mappings in pairs(mappings) do
        vim.validate({
            mode = {mode, 'string'},
            mode_mappings = {mode_mappings, 'table'}
        })
        self.mapping_handles[mode] = self.mapping_handles[mode] or {}
        local prefix = (mode == 'v') and ':<c-u>' or '<cmd>'
        for key, fn in pairs(mode_mappings) do
            vim.validate({key = {key, 'string'}, fn = {fn, 'function'}})
            self.mapping_handles[mode][key] = fn
            vim.api.nvim_buf_set_keymap(self.id, mode, key,
                                        ('%slua require("igit.global").buffers[%d].mapping_handles["%s"]["%s"]()<cr>'):format(
                                            prefix, self.id, mode,
                                            key:gsub('^<', '<lt>')), {})
        end
    end
end

function M:unmapfn(mappings)
    for mode, mode_mappings in pairs(mappings) do
        vim.validate({
            mode = {mode, 'string'},
            mode_mappings = {mode_mappings, 'table'}
        })
        for key, _ in pairs(mode_mappings) do
            vim.api.nvim_buf_del_keymap(self.id, mode, key)
        end
    end
end

function M:clear()
    vim.api.nvim_buf_set_option(self.id, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
    vim.api.nvim_buf_set_option(self.id, 'modifiable', false)
end

function M:append(lines)
    vim.api.nvim_buf_set_option(self.id, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.id, -2, -1, false, lines)
    vim.api.nvim_buf_set_option(self.id, 'modifiable', false)
end

function M:save_view() self.saved_view = vim.fn.winsaveview() end

function M:restore_view()
    if self.saved_view then
        vim.fn.winrestview(self.saved_view)
        self.saved_view = nil
    end
end

function M:reload()
    self:save_view()
    self:clear()
    vutils.jobstart(self.reload_fn(), {
        stdout_flush = function(lines) self:append(lines) end,
        post_exit = function() self:restore_view() end
    })
end

return M
