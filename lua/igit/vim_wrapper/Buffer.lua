local M = require 'igit.datatype.Class'()
local job = require('igit.vim_wrapper.job')
local global = require('igit.global')
local utils = require('igit.utils.utils')

function M.open_or_new(opts)
    vim.validate({
        open_cmd = {opts.open_cmd, 'string'},
        filename = {opts.filename, 'string'},
        post_open_fn = {opts.post_open_fn, 'function', true}
    })
    vim.cmd(('%s %s'):format(opts.open_cmd, opts.filename))
    if opts.post_open_fn then opts.post_open_fn() end
    local id = vim.api.nvim_get_current_buf()

    global.buffers = global.buffers or {}
    if global.buffers[id] == nil then
        global.buffers[id] = M(opts)

        vim.cmd(
            ('autocmd BufDelete <buffer> ++once lua require"igit.global".buffers[%d]=nil'):format(
                id))
        if opts.auto_reload then
            vim.cmd(
                ('autocmd BufEnter <buffer> lua require"igit.global".buffers[%d]:reload()'):format(
                    id))
        end
    end
    return global.buffers[id]
end

function M.get_current_buffer()
    return global.buffers[vim.api.nvim_get_current_buf()]
end

function M:init(opts)
    vim.validate({
        reload_cmd_gen_fn = {opts.reload_cmd_gen_fn, 'function'},
        reload_respect_empty_line = {
            opts.reload_respect_empty_line, 'boolean', true
        },
        post_reload_fn = {opts.pos_reload, 'function', true},
        auto_reload = {opts.auto_reload, 'boolean'},
        mappings = {opts.mappings, 'table', true},
        b = {opts.b, 'table', true},
        bo = {opts.bo, 'table', true},
        wo = {opts.wo, 'table', true}
    })

    self.id = vim.api.nvim_get_current_buf()
    self.reload_cmd_gen_fn = opts.reload_cmd_gen_fn or utils.nop
    self.reload_respect_empty_line = opts.reload_respect_empty_line
    self.post_reload_fn = opts.post_reload_fn or utils.nop
    self.mappings = opts.mappings
    self:mapfn(opts.mappings)
    local ctx = {}
    self.ctx = setmetatable({}, {__index = ctx, __newindex = ctx})

    self.namespace = vim.api.nvim_create_namespace('')

    for k, v in pairs(opts.b or {}) do vim.b[k] = v end
    for k, v in pairs(opts.wo or {}) do vim.wo[k] = v end

    local bo = vim.tbl_extend('force', {
        modifiable = false,
        bufhidden = 'wipe',
        buftype = 'nofile'
    }, opts.bo)
    for k, v in pairs(bo) do vim.bo[k] = v end
    self.filetype = bo.filetype

    self:reload()
end

function M:mark(data, max_num_data)
    self.ctx.mark = self.ctx.mark or {}
    if #self.ctx.mark == max_num_data then self.ctx.mark = {} end
    local index = (#self.ctx.mark % max_num_data) + 1
    self.ctx.mark[index] = vim.tbl_extend('error', data,
                                          {linenr = vim.fn.line('.') - 1})

    vim.api.nvim_buf_clear_namespace(self.id, self.namespace, 1, -1)
    for i, d in ipairs(self.ctx.mark) do
        local hi_group
        if i == 1 then
            hi_group = 'RedrawDebugRecompose'
        elseif i == 2 then
            hi_group = 'DiffAdd'
        end
        vim.api.nvim_buf_add_highlight(self.id, self.namespace, hi_group,
                                       d.linenr, 1, -1)
    end
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
        vim.tbl_extend('error', opts, {ori_items = opts.get_items()})
    vim.bo.buftype = 'acwrite'
    vim.cmd(
        ('autocmd BufWriteCmd <buffer> ++once lua require"igit.global".buffers[%d]:save_edit()'):format(
            self.id))
    self:unmapfn(self.mappings)
    local ori_undo_levels = vim.o.undolevels
    vim.bo.undolevels = -1
    vim.bo.modifiable = true
    vim.cmd('substitute/\\e\\[[0-9;]*m//g')
    vim.bo.undolevels = ori_undo_levels
end

function M:mapfn(mappings)
    if not mappings then return end
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
    if self.saved_view and self.id == vim.api.nvim_get_current_buf() then
        vim.fn.winrestview(self.saved_view)
        self.saved_view = nil
    end
end

function M:reload()
    if self.is_reloading then return end

    self.is_reloading = true
    -- Force trigger syntax on
    vim.api.nvim_buf_set_option(self.id, 'filetype', self.filetype)

    self:save_view()
    self:clear()
    job.runasync(self.reload_cmd_gen_fn(), {
        stdout_flush = function(lines)
            if not self.reload_respect_empty_line then
                lines = vim.tbl_filter(function(e) return #e > 0 end, lines)
            end
            self:append(lines)
        end,
        post_exit = function()
            self:restore_view()
            self.is_reloading = false
            self.post_reload_fn(self.id)
        end
    })
end

return M
