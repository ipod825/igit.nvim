local M = {}
local log = require("ivcs.libp.log")

local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"

function M.path_join(...)
	return table.concat({ ... }, path_sep)
end

function M.find_directory(anchor, dir)
	dir = dir or vim.api.nvim_buf_get_name(0)
	local res = nil
	while #dir > 1 do
		if vim.fn.glob(M.path_join(dir, anchor)) ~= "" then
			return dir
		end
		local ori_len
		ori_len, dir = #dir, M.dirname(dir)
		if #dir == ori_len then
			break
		end
	end
	return res
end

function M.dirname(str)
	vim.validate({ std = { str, "string" } })
	local pat = ("%s[^%s]*$"):format(path_sep, path_sep)
	local name = str:gsub(pat, "")
	return name
end

function M.basename(str)
	vim.validate({ std = { str, "string" } })
	local pat = (".*%s([^%s]+)%s?"):format(path_sep, path_sep, path_sep)
	local name = str:gsub(pat, "%1")
	return name
end

return M
