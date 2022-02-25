local M = {}
local utils = require('igit.utils')
local mapping = require('igit.mapping')
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')

function M.setup(options)
    M.options = M.options or {
        mapping = {},
        args = {'--branches', '--graph'},
        pretty = 'format:"%h %s %cr <%an> %d"'
    }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.config_buffer()
    vim.bo.filetype = 'igit-log'
    vim.bo.modifiable = false
    vim.bo.buftype = 'nofile'
    git.find_and_pin_root()

    mapping.mapfn('log', M.options.mapping)
end

function M.switch() end

function M.reload()
    local buffer = Vbuffer()
    buffer:save_view()
    buffer:clear()
    M.job_tbl = M.job_tbl or {}
    vim.fn.jobstart(git.log(table.concat(M.options.args, ' '),
                            '--pretty=' .. M.options.pretty), {
        on_stdout = function(jid, data)
            M.job_tbl[jid] = M.job_tbl[jid] or {lines = {}}
            local job = M.job_tbl[jid]
            for _, s in ipairs(vim.tbl_flatten(data)) do
                if #s > 0 then table.insert(job.lines, s) end
            end
            if #job.lines > 5000 then
                buffer:append(job.lines)
                M.job_tbl[jid].lines = {}
            end
        end,
        on_exit = function(jid)
            buffer:append(M.job_tbl[jid].lines)
            buffer:restore_view()
            M.job_tbl[jid] = nil
        end
    })
end

function M.open()
    local git_root = git.find_root()
    if git_root then
        vim.cmd(string.format('tab drop %s-log', utils.basename(git_root)))
        M.config_buffer()
        M.reload()
    end
end

return M
