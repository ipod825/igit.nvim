require("igit.libp.utils.string_extension")
local M = require("igit.libp.argparse.Parser"):EXTEND()

function M:parse(str)
	vim.validate({ str = { str, "string" } })
	return self:parse_internal(str:split())
end

function M:parse_internal(args)
	return { { self.prog, args } }
end

return M
