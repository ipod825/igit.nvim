local M = require 'igit.lib.datatype.Class'()
local a = require('igit.lib.async.async')
local job = require('igit.lib.job')

function M:init(filename)
    vim.validate({filename = {filename, 'string'}})

    self.id = vim.api.nvim_create_buf(true, false)

    a.sync(function()
        vim.api.nvim_create_autocmd('BufWriteCmd', {
            buffer = self.id,
            once = true,
            callback = function()
                vim.fn.writefile(vim.api.nvim_buf_get_lines(self.id, 0, -1,
                                                            false), filename)
            end
        })
        vim.api.nvim_buf_set_option(self.id, 'undolevels', -1)
        a.wait(job.run_async('cat ' .. filename, {
            on_stdout = function(lines)
                if not vim.api.nvim_buf_is_valid(self.id) then
                    return true
                end

                vim.api.nvim_buf_set_lines(self.id, -2, -1, false, lines)
            end
        }))
        vim.api.nvim_buf_set_name(self.id, filename)
        vim.api.nvim_buf_set_option(self.id, 'undolevels',
                                    vim.api.nvim_get_option('undolevels'))
        vim.api.nvim_buf_set_option(self.id, 'modified', false)
    end)()
end

return M
