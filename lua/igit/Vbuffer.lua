local M = {}

M.__index = M

setmetatable(M, {__call = function(cls, ...) return cls.new(...) end})

function M.new(id)
    local self = setmetatable({}, M)
    self.id = id or vim.api.nvim_get_current_buf()
    return self
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

return M
