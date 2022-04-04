local M = require("ivcs.libp.ui.Menu"):EXTEND()

function M:init(opts)
	vim.validate({
		title = { opts.title, "string", true },
		content = { opts.content, { "table", "string" } },
		fwin_cfg = { opts.fwin_cfg, "table", true },
		wo = { opts.wo, "table", true },
	})

	opts.title = opts.title or "!"
	if type(opts.content) == "string" then
		opts.content = { opts.content }
	end

	self:SUPER():init(opts)

	self.fwin_cfg.row = math.floor((vim.o.lines - self.fwin_cfg.height) / 2) - 8
	self.fwin_cfg.col = math.floor((vim.o.columns - self.fwin_cfg.width) / 2)
end

return M
