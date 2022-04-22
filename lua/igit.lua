local M = {}
local a = require("plenary.async")
local git = require("igit.git")
local ui = require("libp.ui")
local Job = require("libp.Job")
local default_config = require("igit.default_config")
local log = require("igit.log")

function M.setup(opts)
	opts = vim.tbl_deep_extend("force", default_config, opts or {})

	vim.validate({
		command = { opts.command, "string", true },
	})

	M.log = require("igit.page.Log")():setup(opts.log)
	M.branch = require("igit.page.Branch")():setup(opts.branch)
	M.status = require("igit.page.Status")():setup(opts.status)
	M.define_command(opts)
end

function M.define_command(opts)
	vim.validate({ command = { opts.command, "string" }, git_sub_commands = { opts.git_sub_commands, "table" } })

	local EchoParser = require("libp.argparse.EchoParser")
	local parser = require("libp.argparse.Parser")(opts.command)

	parser:add_subparser(EchoParser("branch"))
	parser:add_subparser(EchoParser("log"))
	parser:add_subparser(EchoParser("status"))
	local sub_commands = {
		"add",
		"checkout",
		"clone",
		"commit",
		"diff",
		"fetch",
		"grep",
		"init",
		"pull",
		"push",
		"rebase",
		"remote",
		"reset",
		"rev-parse",
		"stash",
		"tag",
	}
	vim.list_extend(sub_commands, opts.git_sub_commands)
	for _, cmd in ipairs(sub_commands) do
		parser:add_subparser(EchoParser(cmd))
	end

	local complete = function(arg_lead, cmd_line, cursor_pos)
		local beg = cmd_line:find(" ")
		return parser:get_completion_list(cmd_line:sub(beg, #cmd_line), arg_lead)
	end

	local execute = function(opts)
		a.void(function()
			local args = parser:parse(opts.args, true)
			if not args then
				return
			end

			if #args == 0 then
				table.insert(args.git_cmds, 1, "git")
				Job({
					cmds = args.git_cmds,
					on_stdout = function(lines)
						vim.notify(table.concat(lines, "\n"))
					end,
				}):start()
				return
			end

			assert(#args == 2)
			local module, module_args = unpack(args[2])

			if #module_args == 0 then
				module_args = nil
			end

			if M[module] and not opts.bang then
				local open_cmd = #opts.mods > 0 and opts.mods .. " split" or nil
				M[module]:open(module_args, open_cmd)
			else
				local gita = git.with_default_args({ no_color = true })
				local current_buf = ui.Buffer.get_current_buffer()
				Job({
					cmds = gita[module](module_args),
					stderr_dump_level = Job.StderrDumpLevel.ALWAYS,
					on_stdout = function(lines)
						vim.notify(table.concat(lines, "\n"))
					end,
				}):start()

				if current_buf and vim.api.nvim_buf_get_var(current_buf.id, "git_root") then
					current_buf:reload()
				end
			end
		end)()
	end

	vim.api.nvim_create_user_command(opts.command, execute, {
		nargs = "+",
		bang = true,
		bar = true,
		complete = complete,
	})
end

return M
