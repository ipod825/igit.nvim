local M = {}
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

M.counter = function()
	local counter = 0
	local condvar = a.control.Condvar.new()

	local Sender = {}

	function Sender:send()
		log.warn("send beg", counter)
		counter = counter + 1
		condvar:notify_all()
		log.warn("send end", counter)
	end

	local Receiver = {}

	function Receiver:recv()
		log.warn("recv beg", counter)
		if counter == 0 then
			condvar:wait()
		end
		counter = counter - 1
		log.warn("recv end", counter)
	end

	function Receiver:last()
		if counter == 0 then
			condvar:wait()
		end
		counter = 0
	end

	function Receiver:clear()
		counter = 0
	end

	return Sender, Receiver
end

M.git = setmetatable({}, {
	__index = function(_, cmd)
		return function(...)
			return ("git --no-pager %s %s"):format(cmd, table.concat({ ... }, " "))
		end
	end,
})

return M
