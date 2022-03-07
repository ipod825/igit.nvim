local M = {}

function M:new(...)
    local obj = setmetatable({
        __call = function(cls, ...) return cls:new(...) end
    }, self)
    self.__index = self
    obj:init(...)
    return obj
end

function M:init() end

function M:bind(fn, ...)
    local bind_args = {...}
    return function(...)
        local args = vim.deepcopy(bind_args)
        local new_args = {...}
        vim.list_extend(args, new_args)
        return fn(self, unpack(args))
    end
end

function M:__call(...) return self:new(...) end

setmetatable(M, {__call = function(cls, ...) return cls:new(...) end})

return M
