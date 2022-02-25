local M = {}
local utils = require('igit.utils')

M.__index = M
M.buffers = {}

setmetatable(M, {__call = function(cls, ...) return cls.get_or_new(...) end})

function M.get_or_new(vcs_root, filetype, mappings, reload_fn)
    vim.cmd(('tab drop %s-%s'):format(utils.basename(vcs_root), filetype))
    local id = vim.api.nvim_get_current_buf()
    if M.buffers[id] == nil then
        local self = setmetatable({}, M)
        M.buffers[id] = self
        vim.cmd(
            ('autocmd BufDelete <buffer> ++once lua require"igit.Vbuffer".buffers[%d]=nil'):format(
                id))

        vim.validate({
            vcs_root = {vcs_root, 'string'},
            filetype = {filetype, 'string'},
            mappings = {mappings, 'table'},
            reload_fn = {reload_fn, 'function'}
        })
        self.id = id
        vim.bo.filetype = 'igit-' .. filetype
        vim.bo.modifiable = false
        vim.bo.buftype = 'nofile'
        vim.b.vcs_root = vcs_root
        self.reload_fn = reload_fn

        self:mapfn(mappings)
    end

    M.buffers[id]:reload()
    return M.buffers[id]
end

function M.current()
    local id = vim.api.nvim_get_current_buf()
    return M.buffers[id]
end

function M:mapfn(mappings)
    self.mapping_handles = self.mapping_handles or {}
    for key, fn in pairs(mappings) do
        self.mapping_handles[key] = fn
        vim.api.nvim_buf_set_keymap(0, 'n', key,
                                    ('<cmd>lua require("igit.Vbuffer").buffers[%d].mapping_handles["%s"]()<cr>'):format(
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
    vim.fn.winrestview(self.saved_view)
    self.saved_view = nil
end

function M:reload()
    local lines = {}
    self:save_view()
    self:clear()
    vim.fn.jobstart(self.reload_fn(), {
        on_stdout = function(_, data)
            for _, s in ipairs(vim.tbl_flatten(data)) do
                if #s > 0 then table.insert(lines, s) end
            end
            if #lines > 5000 then
                self:append(lines)
                lines = {}
            end
        end,
        on_exit = function(_)
            self:append(lines)
            self:restore_view()
        end
    })
end

return M
