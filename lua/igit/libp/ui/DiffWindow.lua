local M = require 'igit.libp.ui.Window':EXTEND()

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
    self.wo = vim.tbl_extend('keep', {
        diff = true,
        scrollbind = true,
        cursorbind = true,
        wrap = true,
        foldmethod = 'diff',
        winhighlight = 'Normal:Normal'
    }, opts.wo or {})

    -- opts = opts or {}
    -- opts.wo = vim.tbl_extend('force', opts.wo or {}, {
    --     diff = true,
    --     scrollbind = true,
    --     cursorbind = true,
    --     wrap = true,
    --     foldmethod = 'diff',
    --     winhighlight = 'Normal:Normal'
    -- })
    -- _G.p(getmetatable(self)['init'](self, buffer, opts))
    -- self:super('init')(buffer, opts)
end

return M
