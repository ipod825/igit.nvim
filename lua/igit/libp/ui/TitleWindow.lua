local M = require("igit.libp.ui.Window"):EXTEND()

function M:init(buffer, opts)
	opts = opts or {}
	opts.wo = vim.tbl_extend("force", opts.wo or {}, {
		winhighlight = "Normal:LibpTitle",
	})

	assert(type(buffer.content) == "table")
	buffer:set_content({ require("igit.libp.ui").center_align_text(buffer.content, vim.o.columns) })
	self:SUPER():init(buffer, opts)
end

return M
