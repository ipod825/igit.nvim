local M = {}
local utils = require('igit.utils')
local mapping = require('igit.mapping')
local git = require('igit.git')

function M.setup(options)
    M.options = M.options or {mapping = {['<cr>'] = M.switch}}
    M.options = vim.tbl_deep_extend('force', M.options, options.branch)
end

function M.config_buffer()
    vim.bo.filetype = 'igit-branch'
    vim.bo.modifiable = false
    vim.bo.buftype = 'nofile'
    git.find_and_pin_root()

    mapping.mapfn('branch', M.options.mapping)
end

function M.switch()
    vim.fn.jobstart(git.checkout(vim.fn.getline('.')),
                    {on_exit = function() M.reload() end})
end

function M.reload()
    local buf_id = vim.api.nvim_get_current_buf()
    vim.fn.jobstart(git.branch(), {
        on_stdout = function(jid, data)
            M.job_tbl[jid] = M.job_tbl[jid] or {buffer = {}}
            local job = M.job_tbl[jid]
            for _, s in ipairs(vim.tbl_flatten(data)) do
                if #s > 0 then table.insert(job.buffer, s) end
            end
            -- vim.api.nvim_buf_set_lines(buf_id, -1, -1, false, {d})
        end,
        on_exit = function(jid)
            vim.bo.modifiable = true
            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false,
                                       M.job_tbl[jid].buffer)
            vim.bo.modifiable = false
            M.job_tbl[jid] = nil
        end
    })
end

function M.open()
    M.job_tbl = M.job_tbl or {}
    local git_root = git.find_root()
    if git_root then
        vim.cmd(string.format('tab drop %s-branches', utils.basename(git_root)))
        M.config_buffer()
        M.reload()
    end
end

return M
