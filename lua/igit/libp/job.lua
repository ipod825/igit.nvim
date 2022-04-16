require("igit.libp.datatype.string_extension")
local M = require("igit.libp.datatype.Class"):EXTEND()
local a = require("plenary.async")
local List = require("igit.libp.datatype.List")
local log = require("igit.libp.log")

function M:init(opts)
	vim.validate({
		on_stdout = { opts.on_stdout, "function", true },
		stdout_buffer_size = { opts.stdout_buffer_size, "number", true },
		silent = { opts.silent, "boolean", true },
		cwd = { opts.cwd, "string", true },
		env = { opts.env, "table", true },
		detached = { opts.detached, "boolean", true },
	})

	opts.stdout_buffer_size = opts.stdout_buffer_size or 1
	self.opts = opts
end

local function close_pipe(pipe)
	if not pipe then
		return
	end

	if not pipe:is_closing() then
		pipe:close()
	end
end

local function transform_env(env)
	vim.validate({ env = { env, "table", true } })
	if not env then
		return
	end

	local res = {}
	for k, v in pairs(env) do
		if type(k) == "number" then
			table.insert(res, v)
		elseif type(k) == "string" then
			table.insert(res, k .. "=" .. tostring(v))
		end
	end
	return res
end

M.start = a.wrap(function(self, callback)
	local opts = self.opts
	local stdout_lines = { "" }
	local stderr_lines = ""

	self.stdin = vim.loop.new_pipe(false)
	self.stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)

	local eof_has_new_line = false
	local on_stdout = function(_, data)
		if self.opts.on_stdout then
			if data == nil then
				return
			end

			eof_has_new_line = data:find("\n$")

			-- The last line in stdout_lines is always a "partial line":
			-- 1. At initialization, we initialized it to "".
			-- 2. For a real partial line (data not ending with "\n"), lines[-1] would be non-empty.
			-- 3. For a complete line (data ending with "\n"), lines[-1] would be "".
			local lines = data:split("\n")
			stdout_lines[#stdout_lines] = stdout_lines[#stdout_lines] .. lines[1]
			vim.list_extend(stdout_lines, lines, 2)

			if #stdout_lines >= opts.stdout_buffer_size then
				local partial_line = table.remove(stdout_lines)
				opts.on_stdout(stdout_lines)
				stdout_lines = { partial_line }
			end
		end
	end

	local on_stderr = function(_, data)
		if data then
			stderr_lines = stderr_lines .. data
		end
	end

	local on_exit = function(exit_code, _)
		self.stdout:read_stop()
		stderr:read_stop()

		close_pipe(self.stdin)
		close_pipe(self.stdout)
		close_pipe(stderr)

		if exit_code ~= 0 then
			if not opts.silent and not self.was_killed then
				vim.notify(("Error message from\n%s\n\n%s"):format(table.concat(opts.cmds, " "), stderr_lines))
			end
		elseif opts.on_stdout then
			stdout_lines = eof_has_new_line and vim.list_slice(stdout_lines, 1, #stdout_lines - 1) or stdout_lines
			if #stdout_lines > 0 then
				log.warn(stdout_lines, exit_code, eof_has_new_line)
				opts.on_stdout(stdout_lines)
			end

			if not opts.silent and #stderr_lines > 0 then
				vim.notify(stderr_lines)
			end
		end

		if callback then
			callback(exit_code)
		end
		self.done:notify_all()
	end

	local cmd, args = opts.cmds[1], vim.list_slice(opts.cmds, 2, #opts.cmds)
	-- Remove quotes as spawn will quote each args.
	for i, arg in ipairs(args) do
		args[i] = arg:gsub('([^\\])"', "%1"):gsub("([^\\])'", "%1"):gsub('\\"', '"'):gsub("\\'", "'")
	end

	self.done = a.control.Condvar.new()

	self.process, self.pid = vim.loop.spawn(cmd, {
		stdio = { self.stdin, self.stdout, stderr },
		args = args,
		cwd = opts.cwd,
		detached = opts.detached,
		env = transform_env(opts.env),
	}, vim.schedule_wrap(on_exit))

	if type(self.pid) == "string" then
		stderr_lines = stderr_lines .. ("Command not found: %s"):format(cmd)
		vim.notify(stderr_lines)
		return -1
	else
		self.stdout:read_start(vim.schedule_wrap(on_stdout))
		stderr:read_start(vim.schedule_wrap(on_stderr))
	end
end, 2)

function M:send(data)
	self.stdin:write(data)
end

function M:wait()
	self.done:wait()
end

function M:kill(signal)
	signal = signal or 15
	self.process:kill(signal)
	self.was_killed = true
end

function M:shutdown()
	vim.wait(10, function()
		return not vim.loop.is_active(self.stdout)
	end)
	self.process:kill(15)
	self:wait()
end

function M:check_output(return_list)
	vim.validate({ return_list = { return_list, "boolean", true } })
	local stdout_lines = {}

	self.opts.on_stdout = function(lines)
		vim.list_extend(stdout_lines, lines)
	end

	local exit_code = self:start()
	if exit_code ~= 0 then
		stdout_lines = nil
	end

	if return_list then
		return List(stdout_lines)
	end
	return table.concat(stdout_lines, "\n")
end

M.start_all = a.wrap(function(cmds, opts, callback)
	a.util.run_all(
		List(cmds)
			:map(function(e)
				return a.wrap(function(cb)
					M(vim.tbl_extend("keep", { cmds = e }, opts or {})):start(cb)
				end, 1)
			end)
			:collect(),
		callback
	)
end, 3)

return M
