local M = {}
local a = require("plenary.async")
local git = require("ivcs.vcs.git.git")
local job = require("ivcs.libp.job")

function M:setup(opts)
	opts = opts or {}
	vim.validate({
		command = { opts.command, "string", true },
		log = { opts.log, "table", true },
		branch = { opts.branch, "table", true },
		status = { opts.status, "table", true },
	})
	M.log = require("ivcs.vcs.git.page.Log")(opts.log)
	M.branch = require("ivcs.vcs.git.page.Branch")(opts.branch)
	M.status = require("ivcs.vcs.git.page.Status")(opts.status)
	M.define_command(opts.command or "IGit")
end

function M.define_command(command)
	local PipeParser = require("ivcs.libp.argparse.PipeParser")
	local parser = require("ivcs.libp.argparse.Parser")(command)
	parser:add_argument("--open_cmd")
	parser:add_subparser(PipeParser("branch"))
	parser:add_subparser(PipeParser("log"))
	parser:add_subparser(PipeParser("status"))
	local sub_commands = { "stash", "push", "pull", "rebase" }
	for _, cmd in ipairs(sub_commands) do
		parser:add_subparser(PipeParser(cmd))
	end

	local complete = function(arg_lead, cmd_line, cursor_pos)
		return parser:get_completion_list(cmd_line, arg_lead)
	end

	local execute = function(opts)
		a.void(function()
			local args = parser:parse(opts.args, true)
			if not args then
				return
			end

			if #args <= 1 then
				vim.notify("Not enough arguments!")
				return
			end
			assert(#args == 2)
			local module, module_args = unpack(args[2])

			if #module_args == 0 then
				module_args = nil
			end
			if M[module] and not opts.bang then
				M[module]:open(module_args)
			else
				local gita = git.with_default_args({ no_color = true })
				job.start(gita[module](module_args), {
					on_stdout = function(lines)
						vim.notify(table.concat(lines, "\n"))
					end,
				})
			end
		end)()
	end

	vim.api.nvim_add_user_command(command, execute, {
		nargs = "+",
		bang = true,
		complete = complete,
	})
end

return M