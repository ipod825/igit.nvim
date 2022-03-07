local M = {}

local size_indxe_name = '_______size_______'

function M.new(table)
    table = table or {}
    local obj = {[size_indxe_name] = 0}
    for _, v in ipairs(table) do M.add(obj, v) end
    return obj
end

function M.size(set) return set[size_indxe_name] end

function M._inc(set, s) set[size_indxe_name] = set[size_indxe_name] + s end

function M._dec(set, s) set[size_indxe_name] = set[size_indxe_name] - s end

function M.values(set)
    return coroutine.wrap(function()
        for k, _ in pairs(set) do
            if k ~= size_indxe_name then coroutine.yield(k) end
        end
    end)
end

function M.has(set, e) return rawget(set, e) ~= nil end

function M.add(set, k, v)
    v = v or true
    if rawget(set, k) == nil then
        rawset(set, k, v)
        M._inc(set, 1)
    end
end

function M.remove(set, k)
    if rawget(set, k) ~= nil then
        rawset(set, k, nil)
        M._dec(set, 1)
    end
end

setmetatable(M, {__call = function(cls, ...) return M.new(...) end})

return M
