local M = require 'igit.datatype.DataStructure'()

function M:new(table)
    table = table or {}
    local obj = setmetatable({}, self)
    self.__index = self
    for _, v in ipairs(table) do if (not obj[v]) then obj[v] = true end end
    return obj
end

function M:iter()
    return coroutine.wrap(function()
        for k, _ in pairs(self) do coroutine.yield(k) end
    end)
end

return M
