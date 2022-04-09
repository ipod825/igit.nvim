local M = {}
local log = require("ivcs.libp.log")

local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"

function M.path_join(...)
	return table.concat({ ... }, path_sep)
end

function M.find_directory(anchor, dir)
	vim.validate({ anchor = { anchor, "string" }, dir = { dir, { "string", "table" }, true } })
	if type(dir) == "string" then
		dir = { dir }
	end
	dir = dir or { vim.api.nvim_buf_get_name(0), vim.fn.getcwd() }

	local function search(d)
		local res = nil
		while #d > 1 do
			if vim.fn.glob(M.path_join(d, anchor)) ~= "" then
				return d
			end
			local ori_len
			ori_len, d = #d, M.dirname(d)
			if #d == ori_len then
				break
			end
		end
		return res
	end

	local res
	for _, d in ipairs(dir) do
		res = search(d)
		if res then
			return res
		end
	end
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
