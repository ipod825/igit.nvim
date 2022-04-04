local M = require("ivcs.libp.datatype.Class"):EXTEND()

function M:init(buffer, opts)
	opts = opts or {}
	vim.validate({
		buffer = { buffer, "table" },
		buf_id = { buffer.id, "number" },
		wo = { opts.wo, "table", true },
		focus_on_open = { opts.focus_on_open, "boolean", true },
	})

	self.focus_on_open = opts.focus_on_open
	self.buf_id = buffer.id
	self.wo = opts.wo or {}
end

function M:open(fwin_cfg)
	vim.validate({ fwin_cfg = { fwin_cfg, "table" } })
	self.id = vim.api.nvim_open_win(self.buf_id, self.focus_on_open, fwin_cfg)
	for k, v in pairs(self.wo) do
		vim.api.nvim_win_set_option(self.id, k, v)
	end
	return self.id
end

function M:close()
	if vim.api.nvim_win_is_valid(self.id) then
		vim.api.nvim_win_close(self.id, false)
	end
end

return M
