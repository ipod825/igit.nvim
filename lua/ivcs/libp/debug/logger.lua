local M = require("ivcs.libp.datatype.Class"):EXTEND()

local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
local join = function(...)
	return table.concat({ ... }, path_sep)
end

function M:init(opts)
	self:config(opts)
	self.log_date_format = "%F %H:%M:%S"
	self.format_func = function(arg)
		return vim.inspect(arg, { newline = "" })
	end

	self.logfilename = join(vim.fn.stdpath("cache"), "ivcs.log")

	vim.fn.mkdir(vim.fn.stdpath("cache"), "p")
	self.logfile = assert(io.open(self.logfilename, "a+"))

	for level, levelnr in pairs(vim.log.levels) do
		self[level:lower()] = self:BIND(self.log, levelnr)
	end
end

function M:config(opts)
	opts = vim.tbl_extend("keep", opts or {}, { level = vim.log.levels.WARN })
	self.current_level = opts.level
end

function M:get_filename()
	return self.logfilename
end

function M:set_level(level)
	self.current_level = level
end

function M:get_level()
	return self.current_level
end

function M:set_format_func(handle)
	assert(handle == vim.inspect or type(handle) == "function", "handle must be a function")
	self.format_func = handle
end

function M:log(level, ...)
	if level < self.current_level then
		return false
	end
	local argc = select("#", ...)
	if argc == 0 then
		return true
	end

	local info = debug.getinfo(2, "Sl")
	local header = string.format(
		"[%s][%s] ...%s:%s",
		level,
		os.date(self.log_date_format),
		string.sub(info.short_src, #info.short_src - 15),
		info.currentline
	)
	local parts = { header }
	for i = 1, argc do
		local arg = select(i, ...)
		if arg == nil then
			table.insert(parts, "nil")
		else
			table.insert(parts, self.format_func(arg))
		end
	end
	self.logfile:write(table.concat(parts, "\t"), "\n")
	self.logfile:flush()
end

return M
