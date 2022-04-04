local M = {}
require("igit.libp.datatype.std_extension")
local git = require("igit.git")
local job = require("igit.libp.job")
local a = require("plenary.async")

function M.setup(opts)
	require("igit.log"):config(opts)
	M.log = require("igit.page.Log")(opts)
	M.branch = require("igit.page.Branch")(opts)
	M.status = require("igit.page.Status")(opts)
	M.define_command()
end

function M.define_command()
	local PipeParser = require("igit.libp.argparse.PipeParser")
	local parser = require("igit.libp.argparse.Parser")("IGit")
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

	vim.api.nvim_add_user_command("IGit", execute, {
		nargs = "+",
		bang = true,
		complete = complete,
	})
end

return M
