local M = {}
local utils = require('igit.utils')
local vutils = require('igit.vutils')
local global = require('igit.global')

function M:get_or_new(opts)
    vim.cmd(('tab drop %s-%s'):format(utils.basename(opts.vcs_root),
                                      opts.filetype))
    local id = vim.api.nvim_get_current_buf()
    global.buffers = global.buffers or {}
    if global.buffers[id] == nil then
        vim.validate({
            vcs_root = {opts.vcs_root, 'string'},
            filetype = {opts.filetype, 'string'},
            mappings = {opts.mappings, 'table'},
            reload_fn = {opts.reload_fn, 'function'},
            auto_reload = {opts.auto_reload, 'boolean', true}
        })

        local obj = {}
        setmetatable(obj, self)
        self.__index = self
        global.buffers[id] = obj
        vim.cmd(
            ('autocmd BufDelete <buffer> ++once lua require"igit.global".buffers[%d]=nil'):format(
                id))
        if opts.auto_reload then
            vim.cmd(
                ('autocmd BufEnter <buffer> lua require"igit.global".buffers[%d]:reload()'):format(
                    id))
        end

        obj.id = id
        vim.bo.filetype = 'igit-' .. opts.filetype
        vim.bo.modifiable = false
        vim.bo.bufhidden = 'hide'
        vim.bo.buftype = 'nofile'
        vim.b.vcs_root = opts.vcs_root
        obj.reload_fn = opts.reload_fn

        obj:mapfn(opts.mappings)
    end

    global.buffers[id]:reload()
    return global.buffers[id]
end

function M.current()
    local id = vim.api.nvim_get_current_buf()
    return global.buffers[id]
end

function M:mapfn(mappings)
    self.mapping_handles = self.mapping_handles or {}
    for mode, mode_mappings in pairs(mappings) do
        self.mapping_handles[mode] = self.mapping_handles[mode] or {}
        local prefix = (mode == 'v') and ':<c-u>' or '<cmd>'
        for key, fn in pairs(mode_mappings) do
            self.mapping_handles[mode][key] = fn
            vim.api.nvim_buf_set_keymap(0, mode, key,
                                        ('%slua require("igit.global").buffers[%d].mapping_handles["%s"]["%s"]()<cr>'):format(
                                            prefix, self.id, mode,
                                            key:gsub('^<', '<lt>')), {})
        end
    end
end

function M:clear()
    local saved_modifiable = vim.bo.modifiable
    vim.bo.modifiable = true
    vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
    vim.bo.modifiable = saved_modifiable
end

function M:append(lines)
    local saved_modifiable = vim.bo.modifiable
    vim.bo.modifiable = true
    vim.api.nvim_buf_set_lines(self.id, -2, -1, false, lines)
    vim.bo.modifiable = saved_modifiable
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
