local M = {}
local utils = require('igit.utils')
local vutils = require('igit.vutils')
local global = require('igit.global')

M.__index = M

setmetatable(M, {__call = function(cls, ...) return cls.get_or_new(...) end})

function M.get_or_new(opts)
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

        local self = setmetatable({}, M)
        global.buffers[id] = self
        vim.cmd(
            ('autocmd BufDelete <buffer> ++once lua require"igit.global".buffers[%d]=nil'):format(
                id))
        if opts.auto_reload then
            vim.cmd(
                ('autocmd BufEnter <buffer> lua require"igit.global".buffers[%d]:reload()'):format(
                    id))
        end

        self.id = id
        vim.bo.filetype = 'igit-' .. opts.filetype
        vim.bo.modifiable = false
        vim.bo.bufhidden = 'hide'
        vim.bo.buftype = 'nofile'
        vim.b.vcs_root = opts.vcs_root
        self.reload_fn = opts.reload_fn

        self:mapfn(opts.mappings)
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
    for key, fn in pairs(mappings) do
        self.mapping_handles[key] = fn
        vim.api.nvim_buf_set_keymap(0, 'n', key,
                                    ('<cmd>lua require("igit.global").buffers[%d].mapping_handles["%s"]()<cr>'):format(
                                        self.id, key:gsub('^<', '<lt>')), {})
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
