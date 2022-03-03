local M = {}

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

function M.all_rows() return 1, vim.line('$') end

return M
