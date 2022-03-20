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

    self.fwin_cfg = {
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
    height = height or self.fwin_cfg.height
    height = math.min(height, self.fwin_cfg.height)
    assert(height > 0, "Can't add more rows")

    local fwin_cfg = vim.tbl_extend('force', self.fwin_cfg, {height = height})
    local row = M(fwin_cfg, self.root)
    table.insert(self.children, row)
    self.fwin_cfg.row = self.fwin_cfg.row + height
    self.fwin_cfg.height = self.fwin_cfg.height - height
    return row
end

function M:add_column(width)
    vim.validate({width = {width, 'number', true}})
    width = width or self.fwin_cfg.width
    width = math.min(width, self.fwin_cfg.width)
    assert(width > 0, "Can't add more columns")

    local fwin_cfg = vim.tbl_extend('force', self.fwin_cfg, {width = width})
    local column = M(fwin_cfg, self.root)
    table.insert(self.children, column)
    self.fwin_cfg.col = self.fwin_cfg.col + width
    self.fwin_cfg.width = self.fwin_cfg.width - width
    return column
end

function M:fill_window(window) self.window = window end

function M:vfill_windows(windows)
    local width = math.floor(self.fwin_cfg.width / #windows)
    local last_width = self.fwin_cfg.width - width * (#windows - 1)
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
        local win_id = self.window:open(self.fwin_cfg)
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
