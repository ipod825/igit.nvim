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
            vim.notify(table.concat(stderr_lines, '\n'))
            return
        end
        -- stdout always comes with two empty lines at the end.
        opts.stdout_flush(vim.list_slice(stdout_lines, 1, #stdout_lines - 2))
        opts.post_exit(exit_code)
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

function M.pipesync(cmd)
    local stdout_lines = {}
    vim.fn.jobwait({
        M.jobstart(cmd, {
            stdout_flush = function(lines)
                vim.list_extend(stdout_lines, lines)
            end,
            post_exit = function(code)
                if code ~= 0 then stdout_lines = nil end
            end
        })
    })
    return table.concat(stdout_lines, '\n')
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

return M
