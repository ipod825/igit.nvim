local M = require("ivcs.libp.datatype.Class"):EXTEND()
local Buffer = require("ivcs.libp.ui.Buffer")
local Window = require("ivcs.libp.ui.Window")
local functional = require("ivcs.libp.functional")
local a = require("plenary.async")

function M:init(opts)
	vim.validate({
		title = { opts.title, "string", true },
		content = { opts.content, "table" },
		fwin_cfg = { opts.fwin_cfg, "table", true },
		wo = { opts.wo, "table", true },
		on_select = { opts.on_select, "function", true },
	})

	self.fwin_cfg = vim.tbl_extend("keep", opts.fwin_cfg or {}, {
		relative = "cursor",
		row = 0,
		col = 0,
		width = 0,
		height = 0,
		zindex = 50,
		anchor = "NW",
		border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	})

	self.title = opts.title
	self.on_select = opts.on_select or functional.nop
	self.wo = opts.wo or {}

	local content = opts.title and { "[" .. opts.title .. "]" } or {}
	vim.list_extend(content, opts.content or {})

	self.fwin_cfg.height = #content
	for _, c in ipairs(content) do
		if #c > self.fwin_cfg.width then
			self.fwin_cfg.width = #c
		end
	end

	if self.fwin_cfg.width > #content[1] then
		local diff = self.fwin_cfg.width - #content[1]
		local left_pad = math.floor(diff / 2)
		local right_pad = diff - left_pad
		content[1] = string.rep(" ", left_pad) .. content[1] .. string.rep(" ", right_pad)
	end
	self.buffer = Buffer({
		content = content,
		mappings = {
			n = {
				["<cr>"] = function()
					local text = vim.fn.getline(".")
					vim.api.nvim_win_close(0, true)
					self.on_select(text)
				end,
			},
		},
	})
end

function M:show()
	local w = Window(self.buffer, { focus_on_open = true, wo = self.wo })
	local w_id = w:open(self.fwin_cfg)
	vim.api.nvim_win_set_cursor(w_id, { self.title and 2 or 1, 0 })
	if self.title then
		vim.api.nvim_create_autocmd("CursorMoved", {
			buffer = self.buffer.id,
			callback = function()
				if vim.fn.line(".") == 1 then
					vim.api.nvim_win_set_cursor(w_id, { 2, 0 })
				end
			end,
		})
	end
end

M.select = a.wrap(function(self, callback)
	self.on_select = callback
	self:show()
end, 2)

return M
