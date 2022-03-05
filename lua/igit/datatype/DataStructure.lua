local M = require 'igit.datatype.Class'()

function M:new(table)
    table = table or {}
    local obj = setmetatable(table, self)
    self.__index = self
    return obj
end

return M
