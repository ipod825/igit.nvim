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

M.BufReloadWaiter = Class:EXTEND()
function M.BufReloadWaiter:wait()
	-- The first reload is triggered by Buffer init but not autocmd. Hence
	-- no wait on first time.
	if self.reload_done == nil then
		self.reload_done = ui.Buffer.get_current_buffer():register_reload_notification()
	else
		self.reload_done:wait()
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
