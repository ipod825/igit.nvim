local M = {}
local co = coroutine
local unp = table.unpack ~= nil and table.unpack or unpack

-- Introduction:
-- For the following discussion, we assume `local a=require'async'`.
--
-- An async function is a function that takes a single (optional) callback
-- argument and performs some asynchronous jobs. On the asynchronous job
-- completion (not necessarily at the same time when the async function
-- returns), the callback must be invoked with some arguments, which are caught
-- by an `a.wait`, regarded as the asynchronous outputs. For example,
-- ```
-- 1 local async_fn = function(cb)
-- 2     cb(123)
-- 3     return 456
-- 4 end
-- 5 local main_res = a.sync(function()
-- 6     print(a.wait(async_fn)) -- prints 123
-- 7     return 789
-- 8 end)()
-- 9 print(main_res) -- prints nil
-- ```
-- First note that `async_fn` in line 6 is not actually called. In fact, it's
-- called by the `a.wait` with a magic callback, which basically continue the
-- work after `a.wait`. Regarding the print statements, note that it's 123
-- instead of 456 caught by the `a.wait` in line 6. But how about line 9? Why
-- does it not print 789? To understand that, we need to understand what
-- `a.sync` does. Essentially, `a.sync(fn)()` evaluates to:
-- ```
-- function(cb)
--   if cb then
--     cb(fn())
--   end
-- end()
-- ```
-- The anonymous function actually returns nil (no return statement). That is
-- why we didn't see 789. However, since it satisfies the definition of an async
-- function, it's awaitable. That is, `a.sync` transforms a function that takes
-- no argument into an asyn function (as for how to transform a function with
-- arguments into an async functoin, please see `define_async_fn` below. One
-- thing to note is that `a.wait` can only be used inside an async function
-- (technically a coroutine). The reason is that `a.wait` yields the current
-- coroutine, but the main event loop is not a coroutine.
--
-- A more concrete example that actually performs some asynchronous job would be:
-- ```
-- 1 local async_fn = function(cb)
-- 2     vim.loop.new_timer():start(1000, 0, function() cb(123) end)
-- 3 end
-- 4 a.sync(function()
-- 5     print(a.wait(async_fn)) -- prints 123 secondly (after 1000 milliseconds)
-- 6 end)()
-- 7 print(456) -- print 456 firstly
-- ```
-- Note that 123 is printed after the asynchronous job (timer start) finishes
-- while the 456 print statement is not blocked by the asynchronous job.
--
-- But how do we create an async function that takes arguments? The trick is to
-- use a wrapper function:
-- ```
-- 1 local timer_start = function(time, value)
-- 2     return function(cb)
-- 3         vim.loop.new_timer():start(time, 0, function() cb(value) end)
-- 4     end
-- 5 end
-- 6 a.sync(function()
-- 7     print(a.wait(timer_start(1000, 123))) -- prints 123 secondly (after 1000 milliseconds)
-- 8 end)()
-- 9 print(456) -- print 456 firstly
-- ```
-- Essentially, `timer_start(1000, 123)` in line 7 evaluates to `async_fn` in
-- the previous example.
--
-- What if we want to have timer_start used by both `a.wait` and normal
-- function calls? In such case, use the `define_async_fn` function.
-- ```
-- 1  local timer_start_non_awaitable = function(time, value, cb)
-- 2      vim.loop.new_timer():start(time, 0, function() cb(value) end)
-- 3      return value
-- 4  end
-- 5  local timer_start = a.define_async_fn(timer_start_non_awaitable)
-- 6  a.sync(function()
-- 7      print(a.wait(timer_start(1000, 123))) -- prints 123 finally (after 1000 milliseconds)
-- 8  end)()
-- 9  print(456) -- print 456 firstly
-- 10 print(timer_start_non_awaitable(1000, 789, function() end))  -- print 789 secondly
-- ```
-- In line 5, `timer_start` evaluates to a async function that behaves the same
-- as `timer_start` in the previous example. In line 10, 789 is printed
-- immediately without waiting 1000 milliseconds. One thing to note that if
-- `timer_start_non_awaitable` takes no argument and you don't care about the
-- return value of the asynchronous job (the `cb(value)` part), you can use
-- `a.sync` to transform a normal functoin into an asnyc function as mentioned.
-- The reason that `a.sync` and `a.define_async_fn` can't be unified into a
-- single interface is purely TBA.

function M.define_async_fn(fn)
    local res_async_fn = function(...)
        local async_fn_params = {...}
        return function(cb)
            table.insert(async_fn_params, cb)
            -- if (cb) then table.insert(async_fn_params, 1, cb) end
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
