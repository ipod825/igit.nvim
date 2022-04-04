local M = require("ivcs.libp.ui.Window"):EXTEND()

function M:init(buffer, opts)
	opts = opts or {}
	opts.wo = vim.tbl_extend("force", opts.wo or {}, {
		diff = true,
		scrollbind = true,
		cursorbind = true,
		wrap = true,
		foldmethod = "diff",
		winhighlight = "Normal:Normal",
	})
	self:SUPER():init(buffer, opts)
end

function M:open(fwin_cfg)
	local id = self:SUPER():open(fwin_cfg)
	local ori_win = vim.api.nvim_get_current_win()
	-- Work around on the fold not being updated when the FileBuffer opens an
	-- existing buffer.
	if id ~= ori_win then
		local ori_eventignore = vim.o.eventignore
		vim.o.eventignore = "all"
		vim.api.nvim_set_current_win(id)
		vim.cmd("normal! zX")
		vim.api.nvim_set_current_win(ori_win)
		vim.o.eventignore = ori_eventignore
	else
		vim.cmd("normal! zX")
	end
	return id
end

return M
