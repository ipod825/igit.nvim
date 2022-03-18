local M = {}
local a = require('igit.lib.async.async')
local List = require('igit.lib.datatype.List')
local log = require('igit.log')

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

    local stdout_lines = {''}
    local stderr_lines = {('Error message from\n%s\n'):format(cmd)};
    local terminated_by_client = false
    local jid
    jid = vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if opts.on_stdout then
                -- Handle broken line
                stdout_lines[#stdout_lines] =
                    stdout_lines[#stdout_lines] .. data[1]
                vim.list_extend(stdout_lines, data, 2)

                if #stdout_lines > opts.stdout_buffer_size then
                    local should_terminate = opts.on_stdout(stdout_lines)
                    stdout_lines = {''}
                    if should_terminate then
                        terminated_by_client = true
                        vim.fn.jobstop(jid)
                    end
                end
            end
            if opts.buffer_stdout then
                vim.list_extend(stdout_lines, data)
            end
        end,
        on_stderr = function(_, data) vim.list_extend(stderr_lines, data) end,
        on_exit = function(_, exit_code)
            if exit_code ~= 0 then
                if not opts.silent and not terminated_by_client then
                    vim.notify(table.concat(stderr_lines, '\n'))
                end
            elseif opts.on_stdout then
                -- trim the eof
                opts.on_stdout(
                    vim.list_slice(stdout_lines, 1, #stdout_lines - 1))
            end
            if callback then callback(exit_code) end
        end
    })
    return jid
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

    log.WARN(#stdout_lines, stdout_lines)
    if return_list then return List(stdout_lines) end
    return table.concat(stdout_lines, '\n')
end

return M
