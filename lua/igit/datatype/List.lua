local M = require('igit.datatype.Class')()

function M:new(lst)
    lst = lst or {}
    local obj = setmetatable(lst, self)
    self.__index = self
    return obj
end

function M:__add(that)
    local res = vim.deepcopy(self)
    vim.list_extend(res, that)
    return res
end

function M:append(ele) self[#self + 1] = ele end

function M:extend(that)
    vim.list_extend(self, that)
    return self
end

function M:iter()
    return coroutine.wrap(function()
        for _, e in ipairs(self) do coroutine.yield(e) end
    end)
end

function M:enumerate()
    return coroutine.wrap(function()
        for i, e in ipairs(self) do coroutine.yield(i, e) end
    end)
end

return M
