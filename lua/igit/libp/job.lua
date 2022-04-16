require("igit.libp.datatype.string_extension")
local M = require("igit.libp.datatype.Class"):EXTEND()
local a = require("plenary.async")
local List = require("igit.libp.datatype.List")
local log = require("igit.libp.log")

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

local State = { NOT_STARTED = 1, RUNNING = 2, FINISHED = 3 }

function M:init(opts)
	vim.validate({
		on_stdout = { opts.on_stdout, "function", true },
		on_stdout_buffer_size = { opts.on_stdout_buffer_size, "number", true },
		silent = { opts.silent, "boolean", true },
		cwd = { opts.cwd, "string", true },
		env = { opts.env, "table", true },
		detached = { opts.detached, "boolean", true },
	})

	self.state = State.NOT_STARTED

	-- Default stdout handler that just caches the output.
	if not opts.on_stdout then
		self.stdout_lines = {}
		opts.on_stdout = function(lines)
			vim.list_extend(self.stdout_lines, lines)
		end
	end

	-- Only invokes on_stdout once a while.
	opts.on_stdout_buffer_size = opts.on_stdout_buffer_size or 5000

	self.opts = opts
end

M.start = a.wrap(function(self, callback)
	assert(self.state == State.NOT_STARTED)
	self.state = State.RUNNING

	local opts = self.opts

	self.stdin = vim.loop.new_pipe(false)
	self.stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)
	self.done = a.control.Condvar.new()

	local cmd, args = opts.cmds[1], vim.list_slice(opts.cmds, 2, #opts.cmds)
	-- Remove quotes as spawn will quote each args.
	for i, arg in ipairs(args) do
		args[i] = arg:gsub('([^\\])"', "%1"):gsub("([^\\])'", "%1"):gsub('\\"', '"'):gsub("\\'", "'")
	end

	local stdout_lines = { "" }
	local stderr_lines = ""
	local eof_has_new_line = false
	local on_stdout = function(_, data)
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

		if #stdout_lines >= opts.on_stdout_buffer_size then
			local partial_line = table.remove(stdout_lines)
			opts.on_stdout(stdout_lines)
			stdout_lines = { partial_line }
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
		self.state = State.FINISHED
	end

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

function M:stdoutput()
	if self.state == State.NOT_STARTED then
		self:start()
	end
	return self.stdout_lines
end

function M:stdoutputstr()
	return table.concat(self:stdoutput(), "\n")
end

function M:send(data)
	assert(self.state == State.RUNNING)
	self.stdin:write(data)
end

function M:wait()
	assert(self.state ~= State.NOT_STARTED)
	if self.state == State.FINISHED then
		return
	end
	self.done:wait()
end

function M:kill(signal)
	assert(self.state ~= State.NOT_STARTED)
	if self.state == State.FINISHED then
		return
	end
	signal = signal or 15
	self.process:kill(signal)
	self.was_killed = true
end

function M:shutdown()
	assert(self.state ~= State.NOT_STARTED)
	if self.state == State.FINISHED then
		return
	end
	vim.wait(10, function()
		return not vim.loop.is_active(self.stdout)
	end)
	self.process:kill(15)
	self:wait()
end

M.start_all = a.wrap(function(cmds, opts, callback)
	a.util.run_all(
		List(cmds)
			:to_iter()
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
