local M = {}

function M:new(...)
    local obj = setmetatable({}, self)
    self.__index = self
    obj:init(...)
    return obj
end

function M:init() end

function M:__call(...) return self:new(...) end

setmetatable(M, {__call = function(cls, ...) return cls:new(...) end})

return M
