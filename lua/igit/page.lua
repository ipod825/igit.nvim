local M = {}
local utils = require('igit.utils')
local vutils = require('igit.vutils')
local global = require('igit.global')
local git = require('igit.git')

function M:get_or_new(opts)
    vim.cmd(('tab drop %s-%s'):format(utils.basename(opts.vcs_root),
                                      opts.filetype))
    local id = vim.api.nvim_get_current_buf()
    global.pages = global.pages or {}
    if global.pages[id] == nil then
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
        global.pages[id] = obj
        vim.cmd(
            ('autocmd BufDelete <buffer> ++once lua require"igit.global".pages[%d]=nil'):format(
                id))
        if opts.auto_reload then
            vim.cmd(
                ('autocmd BufEnter <buffer> lua require"igit.global".pages[%d]:reload()'):format(
                    id))
        end

        obj.id = id
        vim.bo.filetype = 'igit-' .. opts.filetype
        vim.bo.modifiable = false
        vim.bo.bufhidden = 'hide'
        vim.bo.buftype = 'nofile'
        git.ping_root_to_buffer()
        obj.reload_fn = opts.reload_fn

        obj:mapfn(opts.mappings)
    end

    global.pages[id]:reload()
    return global.pages[id]
end

function M.current()
    local id = vim.api.nvim_get_current_buf()
    return global.pages[id]
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
            vim.api.nvim_buf_set_keymap(0, mode, key,
                                        ('%slua require("igit.global").pages[%d].mapping_handles["%s"]["%s"]()<cr>'):format(
                                            prefix, self.id, mode,
                                            key:gsub('^<', '<lt>')), {})
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
