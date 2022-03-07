local co = coroutine
local unp = table.unpack ~= nil and table.unpack or unpack
local M = {}

function M.define_async_fn(fn)
    local res_async_fn = function(...)
        local async_fn_params = {...}
        return function(cb)
            table.insert(async_fn_params, cb)
            return fn(unpack(async_fn_params))
        end
    end
    return res_async_fn
end

local function run_till_next_async_fn(thread, current_fn_dead_callback, ...)
    local res = {co.resume(thread, ...)}
    local no_error, yielded_values = res[1], unp(res, 2)
    assert(no_error, yielded_values)

    if co.status(thread) == 'dead' then
        if current_fn_dead_callback then
            current_fn_dead_callback(yielded_values)
        end
    else
        local next_async_fn = res[2]
        local next_async_fn_dead_callback =
            function(...)
                run_till_next_async_fn(thread, current_fn_dead_callback, ...)
            end
        next_async_fn(next_async_fn_dead_callback)
    end
end

M.sync = function(fn)
    vim.validate({fn = {fn, 'function'}})
    return function(cb, ...) run_till_next_async_fn(co.create(fn), cb, ...) end
end

M.wait = function(async_cb)
    vim.validate({async_cb = {async_cb, 'function'}})
    return co.yield(async_cb)
end

M.wait_all = function(async_fns)
    local res = {}
    local sync_all = function(all_dead_callback)
        local to_run = #async_fns
        for i, async_fn in ipairs(async_fns) do
            local async_fn_dead_callback =
                function(...)
                    res[i] = {...}
                    to_run = to_run - 1
                    if to_run == 0 then
                        all_dead_callback(res)
                    end
                end
            async_fn(async_fn_dead_callback)
        end
    end
    return co.yield(sync_all)
end

M.pool = function(n, condition_met, ...)
    vim.validate({
        n = {n, 'number'},
        condition_met = {condition_met, {'function', 'boolean'}, true}
    })
    local async_fns = {...}
    local res = {}
    local num_launched = n
    local total_jobs = #async_fns
    local to_run = total_jobs
    return function(all_dead_callback)
        local async_fn_dead_callback_gen = nil
        async_fn_dead_callback_gen = function(idx)
            return function(...)
                res[idx] = {...}
                to_run = to_run - 1
                if to_run == 0 then
                    all_dead_callback(res)
                elseif not condition_met or not condition_met() then
                    if num_launched < total_jobs then
                        num_launched = num_launched + 1
                        async_fns[num_launched](
                            async_fn_dead_callback_gen(num_launched))
                    end
                elseif to_run <= total_jobs - num_launched then
                    all_dead_callback(res)
                end
            end
        end

        for i = 1, math.min(n, total_jobs) do
            async_fns[i](async_fn_dead_callback_gen(i))
        end
    end
end

function M.wait_pool(n, ...) return co.yield(M.pool(n, false, ...)) end

function M.wait_pool_with_condition(n, condition, ...)
    vim.validate({n = {n, 'number'}, condition = {condition, 'function'}})
    return co.yield(M.pool(n, condition, ...))
end
return M
