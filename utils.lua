local M = {}

function M.path_join(...) return table.concat({...}, '/') end

function M.p(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
end

function M.find_directory(anchor)
    local dir = vim.fn.expand('%:p')
    local res = nil
    while #dir > 1 do
        if vim.fn.glob(M.path_join(dir, anchor)) ~= "" then
            res = dir
            break
        end
        dir = M.dirname(dir)
    end
    return res
end

function M.dirname(str)
    local name = string.gsub(str, "(.*)/(.*)", "%1")
    return name
end

function M.basename(str)
    local name = string.gsub(str, "(.*/)(.*)", "%2")
    return name
end

return M
