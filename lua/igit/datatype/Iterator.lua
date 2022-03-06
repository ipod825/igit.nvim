local M = require 'igit.datatype.Class'()

M.iter = {}
function M:init(opts)
    vim.validate({
        next_fn = {opts.next_fn, 'function'},
        invariant = {opts.invariant, 'table', true},
        control = {opts.controle, 'number', true}
    })

    self.next_fn = opts.next_fn
    self.invariant = opts.invariant
    self.control = opts.control
end

function M:pairs() return self.next_fn, self.invariant, self.control end

function M:collect()
    local res = {}
    for k, v in self:pairs() do res[k] = v end
    return res
end

function M:map(map_fn)
    return M({
        next_fn = coroutine.wrap(function(table, last_index)
            local ori_k, ori_v = self.next_fn(table, last_index)
            last_index = last_index or 0
            while ori_v ~= nil do
                coroutine.yield(ori_k, map_fn(ori_v))
                last_index = last_index + 1
                ori_k, ori_v = self.next_fn(table, last_index)
            end
        end),
        invariant = self.invariant,
        control = self.control
    })
end

function M:filter(filter_fn)
    return M({
        next_fn = coroutine.wrap(function(table, last_index)
            local offset = 0
            local ori_k, ori_v = self.next_fn(table, last_index)
            last_index = last_index or 0
            while ori_v ~= nil do
                if filter_fn(ori_v) then
                    coroutine.yield(ori_k - offset, ori_v)
                else
                    offset = offset + 1
                end
                last_index = last_index + 1
                ori_k, ori_v = self.next_fn(table, last_index)
            end
        end),
        invariant = self.invariant,
        control = self.control
    })
end

function M.range(beg, ends, step)
    if not ends then
        ends = beg
        beg = 1
    end
    step = step or 1
    return M({
        next_fn = coroutine.wrap(function(_, last_index)
            last_index = last_index or 1
            for e = beg, ends, step do
                coroutine.yield(last_index, e)
                last_index = last_index + 1
            end
        end)
    })
end

return M
