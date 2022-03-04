local M = {}
local List = require('igit.ds.List')

M.iter = {}
function M.iter:new(opts)
    vim.validate({next_fn = {opts.next_fn, {'function', 'table'}}})
    if type(opts.next_fn) ~= 'function' then
        opts.invariant = opts.next_fn
        opts.next_fn = next
        opts.control = nil
    end
    opts.map_fn = opts.map_fn or function(e) return e end
    vim.validate({
        next_fn = {opts.next_fn, 'function'},
        invariant = {opts.invariant, 'table', true},
        control = {opts.controle, 'number', true},
        map_fn = {opts.map_fn, 'function'},
        is_list = {opts.is_list, 'boolean', true}
    })

    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    obj.next = opts.next_fn
    obj.invariant = opts.invariant
    obj.control = opts.control
    obj.map_fn = opts.map_fn
    obj.is_list = opts.is_list
    return obj
end
setmetatable(M.iter, {__call = function(cls, ...) return cls:new(...) end})

function M.iter:pairs() return self.next, self.invariant, self.control end

function M.iter:collect()
    local res = {}
    if self.is_list then
        for k in self:pairs() do res[#res + 1] = self.map_fn(k) end
        return List(res)
    else
        for k, v in self:pairs() do res[k] = self.map_fn(v) end
    end
    return res
end

function M.iter:map(map_fn)
    return M.iter({
        next_fn = self.next,
        invariant = self.invariant,
        control = self.control,
        is_list = self.is_list,
        map_fn = function(e) return map_fn(self.map_fn(e)) end
    })
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
    return M.iter({next_fn = f, control = a - step, is_list = true})
end

return M
