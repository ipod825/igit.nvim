local M = {}
require("igit.libp.datatype.std_extension")

function M.setup(opts)
	opts = opts or {}
	require("igit.log"):config(opts)
end

function M.register_vcs_module(module, opts)
	module.setup(opts)
end

return M
