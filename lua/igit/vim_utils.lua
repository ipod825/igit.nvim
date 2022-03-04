local M = {}
local List = require('igit.ds.List')

function M.visual_rows()
    local row_beg, row_end
    _, row_beg, _ = unpack(vim.fn.getpos("'<"))
    _, row_end, _ = unpack(vim.fn.getpos("'>"))
    -- Fallback to normal mode.
    if row_beg == row_end then
        row_beg = vim.fn.line('.')
        row_end = row_beg
    end
    return row_beg, row_end
end

function M.all_rows() return 1, vim.fn.line('$') end

function M.augroup(name, autocmds)
    vim.cmd('augroup ' .. name)
    vim.cmd('autocmd!')
    for cmd in List(autocmds):iter() do vim.cmd('autocmd ' .. cmd) end
    vim.cmd('augroup END')
end

return M
