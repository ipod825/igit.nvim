local M = {}
local a = require('igit.lib.async.async')
local List = require('igit.lib.datatype.List')

function M.jobstart(cmd, opts, callback)
    vim.validate({cmd = {cmd, 'string'}, opts = {opts, 'table'}},
                 {callback = {callback, 'function', true}})

    vim.validate({
        on_stdout = {opts.on_stdout, 'function', true},
        stdout_buffer_size = {opts.stdout_buffer_size, 'number', true},
        buffer_stdout = {opts.buffer_stdout, 'boolean', true},
        silent = {opts.silent, 'boolean', true}
    })

    opts.stdout_buffer_size = opts.stdout_buffer_size or 5000

    local stdout_lines = {}
    local stderr_lines = {('Error message from\n%s\n'):format(cmd)};
    return vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if opts.on_stdout then
                vim.list_extend(stdout_lines, data)
                if #stdout_lines > opts.stdout_buffer_size then
                    opts.on_stdout(stdout_lines)
                    stdout_lines = {}
                end
            end
            if opts.buffer_stdout then
                vim.list_extend(stdout_lines, data)
            end
        end,
        on_stderr = function(_, data) vim.list_extend(stderr_lines, data) end,
        on_exit = function(_, exit_code)
            if exit_code ~= 0 then
                if not opts.silent then
                    vim.notify(table.concat(stderr_lines, '\n'))
                end
            elseif opts.on_stdout then
                -- stdout always comes with two empty lines at the end.
                opts.on_stdout(
                    vim.list_slice(stdout_lines, 1, #stdout_lines - 2))
            end
            if callback then callback(exit_code) end
        end
    })
end

local awaitable_jobstart = a.define_async_fn(M.jobstart)

function M.run_async(cmd, opts)
    return a.sync(function()
        return a.wait(awaitable_jobstart(cmd, opts or {}))
    end)
end

function M.runasync_all(cmds, opts)
    return a.sync(function()
        return a.wait_all(List(cmds):map(
                              function(cmd)
                return awaitable_jobstart(cmd, opts or {})
            end):collect())
    end)
end

function M.run(cmd, opts)
    local exit_code = 0
    local jid = M.jobstart(cmd, opts or {}, function(code) exit_code = code end)
    vim.fn.jobwait({jid})
    return exit_code
end

function M.popen(cmd, return_list)
    local stdout_lines = {}
    local jid = M.jobstart(cmd, {
        on_stdout = function(lines) vim.list_extend(stdout_lines, lines) end
    }, function(code) if code ~= 0 then stdout_lines = nil end end)
    vim.fn.jobwait({jid})

    if return_list then return List(stdout_lines) end
    return table.concat(stdout_lines, '\n')
end

return M
