local M = {}

function M:__call(table) return self:new(table) end
function M:new(table)
    table = table or {}
    local obj = setmetatable(table, self)
    self.__index = self
    return obj
end

setmetatable(M, {__call = function(cls, ...) return cls:new(...) end})
return M
