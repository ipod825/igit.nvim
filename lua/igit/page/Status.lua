local M = require("igit.page.Page"):EXTEND()

function M:setup(options)
	vim.validate({ options = { options, "t" } })
	self.options = options

    return self
end

function M:open(args, open_cmd)
    self:SUPER():open(vim.tbl_deep_extend("force", self.options, {
        open_cmd = open_cmd,
        cmd = "status",
        args = args or self.options.args,
        dirstate_update_handler = cache_hg_revision,
    }))
end

return M
