local M = {}
require("ivcs.libp.datatype.string_extension")

function M.setup(module, opts)
	if type(module) == "string" then
		module = require("ivcs.vcs." .. module)
	end
	module.setup(opts)
end

function M.setup_common(opts)
	opts = opts or {}
	require("ivcs.log"):config(opts.log)
end

return M
