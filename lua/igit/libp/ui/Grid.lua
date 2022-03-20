local M = require 'igit.libp.datatype.Class':EXTEND()

function M:init(opts, root)
    opts = opts or {}
    vim.validate({
        relative = {opts.relative, 'string', true},
        width = {opts.width, 'number', true},
        height = {opts.height, 'number', true},
        row = {opts.row, 'number', true},
        col = {opts.col, 'number', true},
        zindex = {opts.zindex, 'number', true}
    })

    self.geo = {
        relative = opts.relative or 'editor',
        width = opts.width or vim.o.columns,
        height = opts.height or vim.o.lines - 2,
        row = opts.row or 0,
        col = opts.col or 0,
        zindex = opts.zindex or 50,
        anchor = 'NW'
    }

    self.root = root or self
    self.window = nil
    self.children = {}
end

function M:add_row(height)
    vim.validate({height = {height, 'number', true}})
    height = height or self.geo.height
    height = math.min(height, self.geo.height)
    assert(height > 0, "Can't add more rows")

    local geo = vim.tbl_extend('force', self.geo, {height = height})
    local row = M(geo, self.root)
    table.insert(self.children, row)
    self.geo.row = self.geo.row + height
    self.geo.height = self.geo.height - height
    return row
end

function M:add_column(width)
    vim.validate({width = {width, 'number', true}})
    width = width or self.geo.width
    width = math.min(width, self.geo.width)
    assert(width > 0, "Can't add more columns")

    local geo = vim.tbl_extend('force', self.geo, {width = width})
    local column = M(geo, self.root)
    table.insert(self.children, column)
    self.geo.col = self.geo.col + width
    self.geo.width = self.geo.width - width
    return column
end

function M:fill_window(window) self.window = window end

function M:vfill_windows(windows)
    local width = math.floor(self.geo.width / #windows)
    local last_width = self.geo.width - width * (#windows - 1)
    for i, window in ipairs(windows) do
        local column = self:add_column(i == #windows and last_width or width)
        column:fill_window(window)
    end
end

function M:close()
    if self.window then
        self.window:close()
    else
        for _, child in ipairs(self.children) do child:close() end
    end
end

function M:show()
    if self.window then
        local win_id = self.window:open(self.geo)
        vim.api.nvim_create_autocmd('WinClosed', {
            pattern = tostring(win_id),
            once = true,
            callback = function() self.root:close() end
        })
    else
        for _, child in ipairs(self.children) do child:show() end
    end
end

return M
