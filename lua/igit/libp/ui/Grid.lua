local M = require 'igit.libp.datatype.Class'()

function M:init(opts, root, buffer_id)
    opts = opts or {}
    vim.validate({
        relative = {opts.relative, 'string', true},
        width = {opts.width, 'number', true},
        height = {opts.height, 'number', true},
        row = {opts.row, 'number', true},
        col = {opts.col, 'number', true},
        zindex = {opts.zindex, 'number', true},
        buffer_id = {buffer_id, 'number', true}
    })

    self.win_opts = {
        relative = opts.relative or 'editor',
        width = opts.width or vim.o.columns,
        height = opts.height or vim.o.lines - 2,
        row = opts.row or 0,
        col = opts.col or 0,
        zindex = opts.zindex or 50,
        anchor = 'NW'
    }

    self.children = {}
    self.root = root or self
    self.buffer_id = buffer_id
    self.win_ids = {}
end

function M:set_lead() self.is_lead = true end

function M:add_row(height)
    vim.validate({height = {height, 'number', true}})
    height = height or self.win_opts.height
    height = math.min(height, self.win_opts.height)
    assert(height > 0, "Can't add more rows")

    local win_opts = vim.deepcopy(self.win_opts)
    win_opts.height = height
    local row = M(win_opts, self.root)
    table.insert(self.children, row)
    self.win_opts.row = self.win_opts.row + height
    self.win_opts.height = self.win_opts.height - height
    return row
end

function M:fill_column(buffer) return self:fill_columns({buffer}) end

function M:fill_columns(buffers)
    assert(self.win_opts.width > 0, "Can't add more columns")
    vim.validate({buffers = {buffers, 'table'}})
    local width = math.floor(self.win_opts.width / #buffers)
    for i, buffer in ipairs(buffers) do
        vim.validate({id = {buffer.id, 'number'}})
        local win_opts = vim.deepcopy(self.win_opts)
        if i ~= #buffers then win_opts.width = width end
        local column = M(win_opts, self.root, buffer.id)
        table.insert(self.children, column)

        self.win_opts.col = self.win_opts.col + width
        self.win_opts.width = self.win_opts.width - width
    end
    return self.children[#self.children]
end

function M:close()
    for _, win_id in ipairs(self.win_ids) do
        vim.api.nvim_win_close(win_id, false)
        self.win_ids = {}
    end
end

function M:is_root() return self.root == nil end

function M:show()
    if self.buffer_id then
        local win_id = vim.api.nvim_open_win(self.buffer_id, self.is_lead,
                                             self.win_opts)
        self.win_ids = {win_id}
        vim.api.nvim_create_autocmd('WinClosed', {
            pattern = tostring(win_id),
            once = true,
            callback = function() self.root:close() end
        })
    else
        for _, child in ipairs(self.children) do
            vim.list_extend(self.win_ids, child:show())
        end
    end
    return self.win_ids
end

return M
