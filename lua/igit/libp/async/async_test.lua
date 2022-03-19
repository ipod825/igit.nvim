local a = require 'igit.libp.async.async'

local exec = function(cmd)
    return a.sync(function()
        return a.wait(function(cb)
            local stdout_lines = {}
            vim.fn.jobstart(cmd, {
                on_stdout = function(_, data)
                    vim.list_extend(stdout_lines, data)
                end,
                on_exit = function() cb(stdout_lines[1]) end
            })
        end)
    end)
end

local check = function(expected, actual)
    assert(vim.deep_equal(expected, actual),
           ('***** expected= %s actual = %s ******'):format(
               vim.inspect(expected), vim.inspect(actual)))
end

a.sync(function()
    check('a', a.wait(exec('echo a')))
    check({{'a'}, {'b'}}, a.wait_all({exec('echo a'), exec('echo b')}))
    check({{'a'}, {'b'}}, a.wait_pool(1, exec('echo a'), exec('echo b')))
    check({{'a'}, {'b'}}, a.wait_pool(2, exec('echo a'), exec('echo b')))
    check({{'a'}, {'b'}}, a.wait_pool(3, exec('echo a'), exec('echo b')))

    local fn = function() return true end
    check({{'a'}}, a.wait_pool_with_condition(1, fn, exec('sleep 0.1; echo a'),
                                              exec('echo b')))
    check({{'a'}, {'b'}}, a.wait_pool_with_condition(2, fn,
                                                     exec('sleep 0.1; echo a'),
                                                     exec('echo b')))
    check({{'a'}, {'b'}},
          a.wait_pool_with_condition(2, fn, exec('sleep 0.1; echo a'),
                                     exec('sleep 0.1; echo b'), exec('echo c')))
end)()
