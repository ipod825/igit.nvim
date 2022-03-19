local M = require 'igit.libp.datatype.Class'()
local a = require('igit.libp.async.async')
local job = require('igit.libp.job')

function M:init(filename)
    vim.validate({filename = {filename, 'string'}})

    self.id = vim.api.nvim_create_buf(true, false)

    a.sync(function()
        local done = false
        vim.api.nvim_create_autocmd('BufWriteCmd', {
            buffer = self.id,
            callback = function()
                if not done then
                    vim.notify('Buffer is still loading. Save later.')
                end
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

        done = true
        vim.api.nvim_create_autocmd('CursorMoved', {
            buffer = self.id,
            once = true,
            callback = function() vim.api.nvim_command('silent! w!') end
        })
    end)()
end

return M
