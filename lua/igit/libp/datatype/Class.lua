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

function M:SUPER()
    local ori_self = self
    local parent_cls = getmetatable(getmetatable(ori_self))
    return setmetatable({}, {
        __index = function(_, key)
            if type(parent_cls[key]) == 'function' then
                -- Return a member-function-like function that binds to the
                -- original self.
                return function(_, ...)
                    return parent_cls[key](ori_self, ...)
                end
            else
                return ori_self[key]
            end
        end
    })
end

function M:__call(...) return self:NEW(...) end

setmetatable(M, {__call = function(cls, ...) return cls:NEW(...) end})

return M
