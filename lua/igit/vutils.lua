local M = {}
function M.nop() end

function M.jobstart(cmd, opts)
    opts = opts or {}
    vim.validate({
        cmd = {cmd, 'string'},
        stdout_flush = {opts.stdout_flush, 'function', true},
        post_exit = {opts.post_exit, 'function', true},
        on_stdout = {opts.on_stdout, 'function', true},
        on_stderr = {opts.on_stderr, 'function', true},
        on_exit = {opts.on_exit, 'function', true}
    })
    opts.stdout_flush = opts.stdout_flush or M.nop
    opts.post_exit = opts.post_exit or M.nop

    local stdout_lines = {}
    local on_stdout = opts.on_stdout or function(_, data)
        for _, s in ipairs(vim.tbl_flatten(data)) do
            if #s > 0 then table.insert(stdout_lines, s) end
        end
        if #stdout_lines > 5000 then
            opts.stdout_flush(stdout_lines)
            stdout_lines = {}
        end
    end

    local stderr_lines = {('Error message from\n%s\n'):format(cmd)};
    local on_stderr = opts.on_stderr or function(_, data)
        for _, s in ipairs(vim.tbl_flatten(data)) do
            if #s > 0 then table.insert(stderr_lines, s) end
        end
    end

    local on_exit = opts.on_exit or function(_, exit_code)
        if exit_code ~= 0 then
            vim.notify(table.concat(stderr_lines, '\n'))
            return
        end
        if #stdout_lines > 0 then opts.stdout_flush(stdout_lines) end
        opts.post_exit()
    end

    return vim.fn.jobstart(cmd, {
        on_stdout = on_stdout,
        on_stderr = on_stderr,
        on_exit = on_exit
    })
end

function M.jobsyncstart(cmd, opts)
    local jid = M.jobstart(cmd, opts)
    vim.fn.jobwait({jid})
    return jid
end

function M.visual_range()
    local row_beg, row_end, col_beg, col_end
    _, row_beg, col_beg = unpack(vim.fn.getpos("'<"))
    _, row_end, col_end = unpack(vim.fn.getpos("'>"))
    -- Fallback to normal mode.
    if row_beg == row_end then
        row_beg = vim.fn.line('.')
        row_end = row_beg
    end
    return {
        row_beg = row_beg,
        col_beg = col_beg,
        row_end = row_end,
        col_end = col_end
    }
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
    return f, nil, a - step
end

return M
