local M = require("ivcs.libp.datatype.Class"):EXTEND()
local log = require("ivcs.libp.log")

function M:init(buffer, opts)
	opts = opts or {}
	vim.validate({
		buffer = { buffer, "table" },
		buf_id = { buffer.id, "number" },
		wo = { opts.wo, "table", true },
		focus_on_open = { opts.focus_on_open, "boolean", true },
	})

	self.focus_on_open = opts.focus_on_open
	self.buffer = buffer
	self.wo = opts.wo or {}
end

function M:open(fwin_cfg)
	vim.validate({ fwin_cfg = { fwin_cfg, "table" } })
	self.id = vim.api.nvim_open_win(self.buffer.id, self.focus_on_open, fwin_cfg)
	for k, v in pairs(self.wo) do
		vim.api.nvim_win_set_option(self.id, k, v)
	end
	return self.id
end

function M:on_close()
	if vim.api.nvim_win_is_valid(self.id) then
		vim.api.nvim_win_close(self.id, false)
		if not vim.api.nvim_buf_is_valid(self.buffer.id) then
			-- autocmd doesn't nest. Invoke BufUnload by ourselves.
			self.buffer:on_unload()
		end
	end
end

return M
