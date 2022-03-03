local M = {}

function M.path_join(...) return table.concat({...}, '/') end

function M.p(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
end

function M.find_directory(anchor, dir)
    dir = dir or vim.fn.expand('%:p')
    local res = nil
    while #dir > 1 do
        if vim.fn.glob(M.path_join(dir, anchor)) ~= "" then return dir end
        local ori_len
        ori_len, dir = #dir, M.dirname(dir)
        if #dir == ori_len then break end
    end
    return res
end

function M.list(...)
    local list = {}
    for v in ... do list[#list + 1] = v end
    return list
end

function M.set(lst)
    local res = {}
    for _, v in ipairs(lst) do if (not res[v]) then res[v] = true end end
    return res
end

function M.dirname(str)
    vim.validate({std = {str, 'string'}})
    local name = str:gsub("/[^/]*$", "")
    return name
end

function M.basename(str)
    vim.validate({std = {str, 'string'}})
    local name = str:gsub(".*/([^/]+)/?", "%1")
    return name
end

return M
