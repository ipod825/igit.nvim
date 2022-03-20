local M = require 'igit.libp.datatype.Class':EXTEND()

function M:init(buffer, opts)
    opts = opts or {}
    vim.validate({
        buffer = {buffer, 'table'},
        buf_id = {buffer.id, 'number'},
        wo = {opts.wo, 'table', true},
        focus_on_open = {opts.focus_on_open, 'boolean', true}
    })

    self.focus_on_open = opts.focus_on_open
    self.buf_id = buffer.id
    self.win_id = nil
    self.wo = opts.wo or {}
end

function M:open(geo)
    vim.validate({geo = {geo, 'table'}})
    self.win_id = vim.api.nvim_open_win(self.buf_id, self.focus_on_open, geo)
    for k, v in pairs(self.wo) do
        vim.api.nvim_win_set_option(self.win_id, k, v)
    end
    return self.win_id
end

function M:close()
    if vim.api.nvim_win_is_valid(self.win_id) then
        vim.api.nvim_win_close(self.win_id, false)
    end
end

return M
