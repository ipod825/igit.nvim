local M = {}

function M:NEW(...)
    local obj = setmetatable({
        __call = function(cls, ...) return cls:NEW(...) end
    }, self)
    self.__index = self
    obj:init(...)
    return obj
end

function M:EXTEND()
    local obj = setmetatable({
        __call = function(cls, ...) return cls:NEW(...) end
    }, self)
    self.__index = self
    return obj
end

function M:init() end

function M:BIND(fn, ...)
    local bind_args = {...}
    return function(...)
        local args = vim.deepcopy(bind_args)
        local new_args = {...}
        vim.list_extend(args, new_args)
        return fn(self, unpack(args))
    end
end

function M:super(name) return self:BIND(getmetatable(self).__index[name]) end

function M:__call(...) return self:NEW(...) end

setmetatable(M, {__call = function(cls, ...) return cls:NEW(...) end})

return M
