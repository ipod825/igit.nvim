local M = require 'igit.libp.datatype.Class':EXTEND()

function M:init(opts)
    vim.validate({
        title = {opts.title, 'string', true},
        content = {opts.content, 'table'},
        geo_opts = {opts.geo_opts, 'table', true},
        win_opts = {opts.win_opts, 'table', true}
    })

    self.geo_opts = vim.tbl_extend('keep', opts.geo_opts or {}, {
        relative = 'cursor',
        row = 0,
        col = 0,
        width = 0,
        height = 0,
        zindex = 50,
        anchor = 'NW',
        border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"}
    })

    self.title = opts.title
    self.content = opts.title and {'[' .. opts.title .. ']'} or {}
    vim.list_extend(self.content, opts.content)
    self.win_opts = opts.win_opts or {}

    self.geo_opts.height = #self.content
    for _, c in ipairs(self.content) do
        if #c > self.geo_opts.width then self.geo_opts.width = #c end
    end
    if self.geo_opts.width > #self.content[1] then
        local diff = self.geo_opts.width - #self.content[1]
        local left_pad = math.floor((diff) / 2)
        local right_pad = diff - left_pad
        self.content[1] = string.rep(' ', left_pad) .. self.content[1] ..
                              string.rep(' ', right_pad)
    end
end

function M:show()
    local b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, self.content)
    local w = vim.api.nvim_open_win(b, true, self.geo_opts)
    for k, v in pairs(self.win_opts) do vim.api.nvim_win_set_option(w, k, v) end
    if self.title then
        vim.api.nvim_create_autocmd('CursorMoved', {
            buffer = b,
            callback = function()
                if vim.fn.line('.') == 1 then
                    vim.api.nvim_win_set_cursor(w, {2, 0})
                end
            end
        })
    end
end

return M
