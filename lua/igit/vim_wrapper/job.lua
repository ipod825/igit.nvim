local M = {}
local List = require('igit.datatype.List')

function M.nop() end

function M.runasync(cmd, opts)
    opts = opts or {}
    vim.validate({
        cmd = {cmd, 'string'},
        stdout_flush = {opts.stdout_flush, 'function', true},
        silent = {opts.silent, 'boolean', true},
        post_exit = {opts.post_exit, 'function', true},
        on_stdout = {opts.on_stdout, 'function', true},
        on_stderr = {opts.on_stderr, 'function', true},
        on_exit = {opts.on_exit, 'function', true}
    })
    opts.stdout_flush = opts.stdout_flush or M.nop
    opts.post_exit = opts.post_exit or M.nop

    local stdout_lines = {}
    local on_stdout = opts.on_stdout or function(_, data)
        vim.list_extend(stdout_lines, data)
        if #stdout_lines > 5000 then
            opts.stdout_flush(stdout_lines)
            stdout_lines = {}
        end
    end

    local stderr_lines = {('Error message from\n%s\n'):format(cmd)};
    local on_stderr = opts.on_stderr or
                          function(_, data)
            vim.list_extend(stderr_lines, data)
        end

    local on_exit = opts.on_exit or function(_, exit_code)
        if exit_code ~= 0 then
            if not opts.silent then
                vim.notify(table.concat(stderr_lines, '\n'))
            end
        else
            -- stdout always comes with two empty lines at the end.
            opts.stdout_flush(vim.list_slice(stdout_lines, 1, #stdout_lines - 2))
        end
        opts.post_exit(exit_code)
    end

    return vim.fn.jobstart(cmd, {
        on_stdout = on_stdout,
        on_stderr = on_stderr,
        on_exit = on_exit
    })
end

function M.runasync_all(job_specs, on_all_exit)
    local jids = {}
    local num_running = #job_specs
    local exit_codes = {}
    for i, spec in ipairs(job_specs) do
        vim.validate({
            cmd = {spec.cmd, 'string'},
            opts = {spec.opts, 'table', true}
        })
        spec.opts = spec.opts or {}
        local ori_post_exit = spec.opts.post_exit
        spec.opts.post_exit = function(code)
            exit_codes[i] = code
            if ori_post_exit then ori_post_exit(code) end
            -- Not very sure if this leads to race condition. But seems like
            -- the event loop is run single threaded.
            num_running = num_running - 1
            if num_running == 0 then on_all_exit(exit_codes) end
        end
        jids[i] = M.runasync(spec.cmd, spec.opts)
    end
    return jids
end

function M.run(cmd, opts)
    opts = opts or {}
    local exit_code = 0
    local ori_post_exit = opts.post_exit
    opts.post_exit = function(code)
        exit_code = code
        if ori_post_exit then ori_post_exit(code) end
    end

    local jid = M.runasync(cmd, opts)
    vim.fn.jobwait({jid})
    return exit_code
end

function M.run_all(job_specs)
    local exit_codes
    local jids = M.runasync_all(job_specs,
                                function(codes) exit_codes = codes end)
    vim.fn.jobwait(jids)
    return exit_codes
end

function M.popen(cmd, return_list)
    local stdout_lines = {}
    M.run(cmd, {
        stdout_flush = function(lines)
            vim.list_extend(stdout_lines, lines)
        end,
        post_exit = function(code)
            if code ~= 0 then stdout_lines = nil end
        end
    })
    if return_list then return List(stdout_lines) end
    return table.concat(stdout_lines, '\n')
end

return M
