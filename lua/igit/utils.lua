local M = {}

function M.path_join(...) return table.concat({...}, '/') end

function M.p(...)
    local objects = vim.tbl_map(vim.inspect, {...})
    print(unpack(objects))
end

function M.find_directory(anchor)
    local dir = vim.fn.expand('%:p')
    local res = nil
    while #dir > 1 do
        if vim.fn.glob(M.path_join(dir, anchor)) ~= "" then
            res = dir
            break
        end
        dir = M.dirname(dir)
    end
    return res
end

function M.dirname(str)
    local name = string.gsub(str, "(.*)/(.*)", "%1")
    return name
end

function M.basename(str)
    local name = string.gsub(str, "(.*/)(.*)", "%2")
    return name
end

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

    local stderr_lines = {};
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

return M
