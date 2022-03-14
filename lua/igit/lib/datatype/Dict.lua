local M = {}

function M.keys(tbl)
    vim.validate({tbl = {tbl, 'table'}})
    local res = {}
    for k, _ in pairs(tbl) do table.insert(res, k) end
    return res
end
return M
