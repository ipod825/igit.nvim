local M = {}
require("ivcs.libp.datatype.string_extension")

function M.setup(opts)
	opts = opts or {}
	require("ivcs.log"):config(opts)
end

function M.register_vcs_module(module, opts)
	module.setup(opts)
end

return M
