local M = require 'igit.datatype.Class'()

function M:new(table)
    table = table or {}
    local obj = setmetatable({__size__ = 0}, self)
    self.__index = self
    for _, v in ipairs(table) do obj:add(v) end
    return obj
end

function M:size() return self.__size__ end

function M:_inc(s) self.__size__ = self.__size__ + s end

function M:_dec(s) self.__size__ = self.__size__ - s end

function M:iter()
    return coroutine.wrap(function()
        for k, _ in pairs(self) do
            if k ~= '__size__' then coroutine.yield(k) end
        end
    end)
end

function M:has(e) return self[e] ~= nil end

function M:add(k, v)
    v = v or true
    if self[k] == nil then
        self[k] = v
        self:_inc(1)
    end
end

function M:remove(k)
    if self[k] ~= nil then
        self[k] = nil
        self:_dec(1)
    end
end

return M
