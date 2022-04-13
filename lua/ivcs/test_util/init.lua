require("ivcs.libp.datatype.string_extension")
local M = {}
local Class = require("ivcs.libp.datatype.Class")
local ui = require("ivcs.libp.ui")
local a = require("plenary.async")
local log = require("ivcs.log")

function M.jobrun(cmd, opts)
	vim.fn.jobwait({ vim.fn.jobstart(cmd, opts or { cwd = "." }) })
end

function M.check_output(cmd)
	return vim.fn.trim(vim.fn.system(cmd)):split_trim("\n")
end

function M.setrow(nr)
	vim.api.nvim_win_set_cursor(0, { nr, 0 })
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

M.VisualRowStub = function(...)
	-- todo: Seems like neovim has a bug: After setting the buffer content,
	-- vim.fn.getpos("'>") would return {0,0,0,0}.
	local stub = visual_rows_stub or require("luassert.stub")(require("ivcs.libp.vimfn"), "visual_rows")
	stub.by_default.returns(...)
	return stub
end

function M.stub_visual_rows(...)
	M.visual_rows_stub = M.visual_rows_stub or require("luassert.stub")(require("ivcs.libp.vimfn"), "visual_rows")
	M.visual_rows_stub.by_default.returns(...)
	return M.visual_rows_stub
end

M.BufReloadWaiter = Class:EXTEND()
function M.BufReloadWaiter:wait(times)
	-- The first reload is triggered by Buffer init but not autocmd. Hence
	-- no wait on first time.
	if self.reload_done == nil then
		self.reload_done = ui.Buffer.get_current_buffer():register_reload_notification()
	else
		times = times or 1
		for _ = 1, times do
			self.reload_done:wait()
		end
	end
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
