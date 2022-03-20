local M = require 'igit.libp.datatype.Class':EXTEND()
local a = require('igit.libp.async.async')
local job = require('igit.libp.job')

function M:init(filename)
    vim.validate({filename = {filename, 'string'}})

    if vim.fn.bufexists(filename) > 0 then
        self.id = vim.fn.bufadd(filename)
        return self.id
    end

    self.id = vim.api.nvim_create_buf(true, false)

    a.sync(function()
        vim.api.nvim_buf_set_option(self.id, 'modifiable', false)
        vim.api.nvim_buf_set_option(self.id, 'undolevels', -1)

        a.wait(job.run_async('cat ' .. filename, {
            on_stdout = function(lines)
                if not vim.api.nvim_buf_is_valid(self.id) then
                    return true
                end

                vim.api.nvim_buf_set_option(self.id, 'modifiable', true)
                vim.api.nvim_buf_set_lines(self.id, -2, -1, false, lines)
                vim.api.nvim_buf_set_option(self.id, 'modifiable', false)
            end
        }))
        vim.api.nvim_buf_set_name(self.id, filename)
        vim.api.nvim_buf_set_option(self.id, 'undolevels',
                                    vim.api.nvim_get_option('undolevels'))
        vim.api.nvim_buf_set_option(self.id, 'modified', false)
        vim.api.nvim_buf_set_option(self.id, 'modifiable', true)

        -- nvim_buf_set_name only associates the buffer with the filename. On
        -- first write, E13 (file exists) happens. The workaround here just
        -- force wrintg the file (or do it on next bufer enter). This can be
        -- improved when there's an API for writing a buffer to a file that
        -- takes a buf id.
        if vim.api.nvim_get_current_buf() == self.id then
            vim.api.nvim_command('silent! w!')
        else
            vim.api.nvim_create_autocmd('BufEnter', {
                buffer = self.id,
                once = true,
                callback = function()
                    vim.api.nvim_command('silent! w!')
                end
            })
        end
    end)()
end

return M
