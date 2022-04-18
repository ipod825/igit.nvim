local M = {}
local a = require("plenary.async")
local git = require("igit.git")
local Job = require("igit.libp.job")
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
	M.define_command(opts.command)
end

function M.define_command(command)
	local EchoParser = require("igit.libp.argparse.EchoParser")
	local parser = require("igit.libp.argparse.Parser")(command)
	parser:add_argument("--open_cmd")
	parser:add_subparser(EchoParser("branch"))
	parser:add_subparser(EchoParser("log"))
	parser:add_subparser(EchoParser("status"))
	local sub_commands = { "stash", "push", "pull", "rebase" }
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
				local open_cmd = #opts.mods > 0 and opts.mods .. " split" or nil
				M[module]:open(module_args, open_cmd)
			else
				local gita = git.with_default_args({ no_color = true })
				Job({
					cmds = gita[module](module_args),
					on_stdout = function(lines)
						vim.notify(table.concat(lines, "\n"))
					end,
				}):start()
			end
		end)()
	end

	vim.api.nvim_create_user_command(command, execute, {
		nargs = "+",
		bang = true,
		complete = complete,
	})
end

return M
