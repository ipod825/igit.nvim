local M = require("igit.libp.datatype.Class"):EXTEND()
local Buffer = require("igit.libp.ui.Buffer")
local a = require("plenary.async")
local log = require("igit.libp.log")

function M:init(opts, root)
	opts = opts or {}
	vim.validate({
		relative = { opts.relative, "string", true },
		width = { opts.width, "number", true },
		height = { opts.height, "number", true },
		row = { opts.row, "number", true },
		col = { opts.col, "number", true },
		zindex = { opts.zindex, "number", true },
		focusable = { opts.focusable, "boolean", true },
	})

	self.fwin_cfg = {
		relative = opts.relative or "editor",
		width = opts.width or vim.o.columns,
		height = opts.height or vim.o.lines - 2,
		row = opts.row or 0,
		col = opts.col or 0,
		zindex = opts.zindex or 50,
		focusable = opts.focusable or false,
		anchor = "NW",
	}

	self.root = root or self
	self.window = nil
	self.children = {}
end

function M:add_row(opts)
	opts = opts or {}
	vim.validate({
		height = { opts.height, "number", true },
		focusable = { opts.focusable, "boolean", true },
	})

	local height = opts.height
	if height and height < 0 then
		height = self.fwin_cfg.height + height
	end
	height = height or self.fwin_cfg.height
	height = math.min(height, self.fwin_cfg.height)
	assert(height > 0, ("Can't add more rows %d %d"):format(height, self.fwin_cfg.height))

	local fwin_cfg = vim.tbl_extend("force", self.fwin_cfg, { height = height })
	fwin_cfg.focusable = opts.focusable
	local row = M(fwin_cfg, self.root)
	table.insert(self.children, row)
	self.fwin_cfg.row = self.fwin_cfg.row + height
	self.fwin_cfg.height = self.fwin_cfg.height - height
	return row
end

function M:add_column(opts)
	opts = opts or {}
	vim.validate({
		width = { opts.width, "number", true },
		focusable = { opts.focusable, "boolean", true },
	})

	local width = opts.width
	width = width or self.fwin_cfg.width
	width = math.min(width, self.fwin_cfg.width)
	assert(width > 0, "Can't add more columns")

	local fwin_cfg = vim.tbl_extend("force", self.fwin_cfg, { width = width })
	fwin_cfg.focusable = opts.focusable
	local column = M(fwin_cfg, self.root)
	table.insert(self.children, column)
	self.fwin_cfg.col = self.fwin_cfg.col + width
	self.fwin_cfg.width = self.fwin_cfg.width - width
	return column
end

function M:fill_window(window)
	self.window = window
end

function M:vfill_windows(windows)
	local width = math.floor(self.fwin_cfg.width / #windows)
	local last_width = self.fwin_cfg.width - width * (#windows - 1)
	for i, window in ipairs(windows) do
		local column = self:add_column({
			width = (i == #windows and last_width or width),
			focusable = self.fwin_cfg.focusable,
		})
		column:fill_window(window)
	end
end

function M:close()
	if self.window then
		self.window:on_close()
	else
		for _, child in ipairs(self.children) do
			child:close()
		end
	end
end

function M:show()
	if self.window then
		local win_id = self.window:open(self.fwin_cfg)
		vim.api.nvim_create_autocmd("WinClosed", {
			pattern = tostring(win_id),
			once = true,
			callback = function()
				self.root:close()
				-- autocmd doesn't nest. Invoke BufEnter by ourselves.
				vim.api.nvim_exec_autocmds("BufEnter", { pattern = "*" })
			end,
		})
	else
		for _, child in ipairs(self.children) do
			child:show()
		end
	end
end

return M
