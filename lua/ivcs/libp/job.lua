local M = {}
local a = require("plenary.async")
local List = require("ivcs.libp.datatype.List")
local log = require("ivcs.log")

M.new_start = a.wrap(function(cmd, opts, callback)
	vim.validate(
		{ cmd = { cmd, "string" }, opts = { opts, "table", true } },
		{ callback = { callback, "function", true } }
	)
	opts = opts or {}

	vim.validate({
		on_stdout = { opts.on_stdout, "function", true },
		stdout_buffer_size = { opts.stdout_buffer_size, "number", true },
		buffer_stdout = { opts.buffer_stdout, "boolean", true },
		silent = { opts.silent, "boolean", true },
	})

	opts.stdout_buffer_size = opts.stdout_buffer_size or 5000

	local stdout_lines = { "" }
	local stderr_lines = ""
	local terminated_by_client = false
	local process
	local pid

	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)

	local on_stdout = function(_, data)
		if opts.on_stdout then
			if data == nil then
				return
			end
			log.warn(data)
			local partial = data:sub(#data, #data) ~= "\n"
			local lines = data:split("\n")

			-- We assume the last line in stdout_lines is a partial line. If it
			-- is not, we add an empty string to make it a partial line. This
			-- simplifies the logic.
			stdout_lines[#stdout_lines] = stdout_lines[#stdout_lines] .. lines[1]
			vim.list_extend(stdout_lines, lines, 2)
			if not partial then
				table.insert(stdout_lines, "")
			end

			if #stdout_lines > opts.stdout_buffer_size then
				-- We send out to client only complete lines with an appended
				-- empty string at the end, which was added to be consistent
				-- with Buffer's append function.
				local partial_line = ""
				if partial then
					partial_line = table.remove(stdout_lines)
				end
				table.insert(stdout_lines, "")
				local should_terminate = opts.on_stdout(stdout_lines)
				stdout_lines = { partial_line }

				if should_terminate then
					terminated_by_client = true
					process:kill(15)
				end
			end
		end
		if opts.buffer_stdout then
			vim.list_extend(stdout_lines, data)
		end
	end

	local on_stderr = function(_, data)
		if data then
			stderr_lines = stderr_lines .. data
		end
	end

	local on_exit = function(exit_code, _)
		stdout:read_stop()
		stderr:read_stop()

		if not stdout:is_closing() then
			stdout:close()
		end
		if not stderr:is_closing() then
			stderr:close()
		end

		if exit_code ~= 0 then
			if not opts.silent and not terminated_by_client then
				vim.schedule_wrap(function()
					vim.notify(stderr_lines)
				end)
			end
		elseif opts.on_stdout then
			-- Trim the added empty lines as its unnecessary for the last call.
			opts.on_stdout(vim.list_slice(stdout_lines, 1, #stdout_lines - 1))
		end
		if callback then
			callback(exit_code)
		end
	end

	local args = cmd:split_trim(" ")
	cmd = args[1]
	args = vim.list_slice(args, 2, #args)
	process, pid = vim.loop.spawn(
		cmd,
		{ stdio = { nil, stdout, stderr }, args = args, cwd = opts.cwd },
		vim.schedule_wrap(on_exit)
	)
	stdout:read_start(vim.schedule_wrap(on_stdout))
	stderr:read_start(on_stderr)

	return pid
end, 3)

M.start = a.wrap(function(cmd, opts, callback)
	vim.validate(
		{ cmd = { cmd, "string" }, opts = { opts, "table", true } },
		{ callback = { callback, "function", true } }
	)
	opts = opts or {}

	vim.validate({
		on_stdout = { opts.on_stdout, "function", true },
		stdout_buffer_size = { opts.stdout_buffer_size, "number", true },
		buffer_stdout = { opts.buffer_stdout, "boolean", true },
		silent = { opts.silent, "boolean", true },
	})

	opts.stdout_buffer_size = opts.stdout_buffer_size or 5000

	local stdout_lines = { "" }
	local stderr_lines = { ("Error message from\n%s\n"):format(cmd) }
	local terminated_by_client = false
	local jid

	jid = vim.fn.jobstart(cmd, {
		cwd = opts.cwd,
		on_stdout = function(_, data)
			if opts.on_stdout then
				-- The last line might be partial
				stdout_lines[#stdout_lines] = stdout_lines[#stdout_lines] .. data[1]
				vim.list_extend(stdout_lines, data, 2)

				if #stdout_lines > opts.stdout_buffer_size then
					-- Though the document said foobar may arrive as ['fo'],
					-- ['obar'], indicating that we should probably not flush
					-- the last line. However, in practice, the last line seems
					-- to be always ''. For efficiency and consistency with
					-- Buffer's append function, which assumes that the last
					-- line is '', we don't do slice here.
					local should_terminate = opts.on_stdout(stdout_lines)
					stdout_lines = { "" }

					if should_terminate then
						terminated_by_client = true
						vim.fn.jobstop(jid)
					end
				end
			end
			if opts.buffer_stdout then
				vim.list_extend(stdout_lines, data)
			end
		end,
		on_stderr = function(_, data)
			vim.list_extend(stderr_lines, data)
		end,
		on_exit = function(_, exit_code)
			if exit_code ~= 0 then
				if not opts.silent and not terminated_by_client then
					vim.notify(table.concat(stderr_lines, "\n"))
				end
			elseif opts.on_stdout then
				-- trim the eof
				opts.on_stdout(vim.list_slice(stdout_lines, 1, #stdout_lines - 1))
			end
			if callback then
				callback(exit_code)
			end
		end,
	})
	return jid
end, 3)

M.start_all = a.wrap(function(cmds, opts, callback)
	a.util.run_all(
		List(cmds)
			:map(function(cmd)
				return a.wrap(function(cb)
					M.start(cmd, opts, cb)
				end, 1)
			end)
			:collect(),
		callback
	)
end, 3)

M.check_output = function(cmd, return_list)
	local stdout_lines = {}
	local exit_code = M.start(cmd, {
		on_stdout = function(lines)
			vim.list_extend(stdout_lines, lines)
		end,
	})
	if exit_code ~= 0 then
		stdout_lines = nil
	end

	if return_list then
		return List(stdout_lines)
	end
	return table.concat(stdout_lines, "\n")
end

return M
