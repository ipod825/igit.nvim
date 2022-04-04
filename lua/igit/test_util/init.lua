local M = {}

function M.jobrun(cmd, opts)
    vim.fn.jobwait({vim.fn.jobstart(cmd, opts or {cwd = '.'})})
end

function M.check_output(cmd) return vim.fn.trim(vim.fn.system(cmd)):split('\n') end

function M.setrow(nr) vim.api.nvim_win_set_cursor(0, {nr, 0}) end

M.git = setmetatable({}, {
    __index = function(_, cmd)
        return function(...)
            return
                ('git --no-pager %s %s'):format(cmd, table.concat({...}, ' '))
        end
    end
})

return M
