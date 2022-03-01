local M = {}

M.iter = {}
function M.iter:new(next_fn, invariant, control, map_fn)
    if type(next_fn) ~= 'function' then
        invariant = next_fn
        next_fn = next
        control = nil
    end
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    obj.next = next_fn
    obj.invariant = invariant
    obj.control = control
    obj.map_fn = map_fn or function(e) return e end
    return obj
end
setmetatable(M.iter, {__call = function(cls, ...) return cls:new(...) end})

function M.iter:pairs() return self.next, self.invariant, self.control end

function M.iter:collect()
    local res = {}
    for k, v in self:pairs() do
        if v == nil then
            res[#res + 1] = self.map_fn(k)
        else
            res[k] = self.map_fn(v)
        end
    end
    return res
end

function M.iter:map(map_fn)
    return M.iter(self.next, self.invariant, self.control,
                  function(e) return map_fn(self.map_fn(e)) end)
end

function M.range(a, b, step)
    if not b then
        b = a
        a = 1
    end
    step = step or 1
    local f = step > 0 and function(_, lastvalue)
        local nextvalue = lastvalue + step
        if nextvalue <= b then return nextvalue end
    end or step < 0 and function(_, lastvalue)
        local nextvalue = lastvalue + step
        if nextvalue >= b then return nextvalue end
    end or function(_, lastvalue) return lastvalue end
    return M.iter(f, nil, a - step)
end

return M
