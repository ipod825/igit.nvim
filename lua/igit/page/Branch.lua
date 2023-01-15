local M = require("igit.page.ReferencePage"):EXTEND()

function M:setup(options)
    vim.validate({ options = { options, "t" } })
    self.options = options

    return self
end

function M:open(args, open_cmd)
    self:SUPER():open(vim.tbl_deep_extend("force", self.options, {
        open_cmd = open_cmd,
        cmd = "branch",
        args = args or self.options.args,
    }))
end

return M
