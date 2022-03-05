local M = require 'igit.datatype.Class'()

function M:new(table)
    table = table or {}
    local obj = setmetatable({__size__ = 0}, self)
    self.__index = self
    for _, v in ipairs(table) do obj:add(v) end
    return obj
end

function M:inc(s) self.__size__ = self.__size__ + s end

function M:dec(s) self.__size__ = self.__size__ - s end

function M:iter()
    return coroutine.wrap(function()
        for k, _ in pairs(self) do coroutine.yield(k) end
    end)
end

function M:size() return self.__size__ end

function M:has(e) return self[e] end

function M:add(k, v)
    v = v or true
    if not self[k] then
        self[k] = v
        self:inc(1)
        return k
    end
    return nil
end

return M
