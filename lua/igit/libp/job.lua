local M = {}
local a = require('plenary.async')
local List = require('igit.libp.datatype.List')
local log = require('igit.log')

function M.jobstart(cmd, opts, callback)
    vim.validate({cmd = {cmd, 'string'}, opts = {opts, 'table', true}},
                 {callback = {callback, 'function', true}})
    opts = opts or {}

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
                -- The last line might be partial
                stdout_lines[#stdout_lines] =
                    stdout_lines[#stdout_lines] .. data[1]
                vim.list_extend(stdout_lines, data, 2)

                if #stdout_lines > opts.stdout_buffer_size then
                    -- Though the document said foobar may arrive as ['fo'],
                    -- ['obar'], indicating that we should probably not flush
                    -- the last line. However, in practice, the last line seems
                    -- to be always ''. For efficiency and consistency with
                    -- Buffer's append function, which assumes that the last
                    -- line is '', we don't do slice here.
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

M.run_async = a.wrap(M.jobstart, 3)

M.runasync_all = a.wrap(function(cmds, opts, callback)
    a.util.run_all(List(cmds):map(function(cmd)
        return a.wrap(function(cb) M.jobstart(cmd, opts, cb) end, 1)
    end):collect(), callback)
end, 3)

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
