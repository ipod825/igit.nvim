local M = require 'igit.libp.ui.Window':EXTEND()

function M:init(buffer, opts)
    opts = opts or {}
    opts.wo = vim.tbl_extend('force', opts.wo or {}, {
        diff = true,
        scrollbind = true,
        cursorbind = true,
        wrap = true,
        foldmethod = 'diff',
        winhighlight = 'Normal:Normal'
    })
    self:SUPER():init(buffer, opts)
end

return M
