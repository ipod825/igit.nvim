require("libp.utils.string_extension")
local M = {}
local log = require("igit.log")

function M.jobrun(cmd, opts)
	vim.fn.jobwait({ vim.fn.jobstart(cmd, opts or { cwd = "." }) })
end

function M.check_output(cmd)
	return vim.fn.trim(vim.fn.system(cmd)):split_trim("\n")
end

function M.set_current_line(str)
	local ori_line = vim.api.nvim_get_current_line()
	local linenr = vim.fn.line(".") - 1
	local ori_modifiable = vim.bo.modifiable
	vim.bo.modifiable = true
	vim.api.nvim_buf_set_lines(0, linenr, linenr + 1, true, { str })
	vim.bo.modifiable = ori_modifiable
	return ori_line
end

function M.assert_diff_window_compaitability()
	assert.are.same(true, vim.wo.diff)
	assert.are.same(true, vim.wo.scrollbind)
	assert.are.same(true, vim.wo.cursorbind)
	assert.are.same(vim.o.diffopt:find("followwrap") ~= nil, vim.wo.wrap)
	assert.are.same("diff", vim.wo.foldmethod)
end

function M.new_name(ori)
	return ori .. "new"
end

M.git = setmetatable({}, {
	__index = function(_, cmd)
		return function(...)
			return ("git --no-pager %s %s"):format(cmd, table.concat({ ... }, " "))
		end
	end,
})

return M
