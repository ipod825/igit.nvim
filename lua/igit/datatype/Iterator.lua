local M = require 'igit.datatype.Class'()
local List = require('igit.datatype.List')

M.iter = {}
function M:init(opts)
    opts.map_fn = opts.map_fn or function(e) return e end
    vim.validate({
        next_fn = {opts.next_fn, 'function'},
        invariant = {opts.invariant, 'table', true},
        control = {opts.controle, 'number', true},
        map_fn = {opts.map_fn, 'function'}
    })

    self.next = opts.next_fn
    self.invariant = opts.invariant
    self.control = opts.control
    self.map_fn = opts.map_fn
end

function M:pairs() return self.next, self.invariant, self.control end

function M:collect()
    local res = {}
    for k, v in self:pairs() do res[k] = self.map_fn(v) end
    return res
end

function M:map(map_fn)
    return M({
        next_fn = self.next,
        invariant = self.invariant,
        control = self.control,
        map_fn = function(e) return map_fn(self.map_fn(e)) end
    })
end

function M.range(beg, ends, step)
    if not ends then
        ends = beg
        beg = 1
    end
    step = step or 1
    return M({
        next_fn = coroutine.wrap(function()
            local i = 1
            for e = beg, ends, step do
                coroutine.yield(i, e)
                i = i + 1
            end
        end)
    })
end

return M
