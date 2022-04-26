require("libp.utils.string_extension")
local M = {}
local path = require("libp.path")
local Job = require("libp.Job")
local log = require("igit.log")

local arg_strcat_factory = function(git_cmd)
	if git_cmd then
		return function(...)
			local args = git_cmd
			for _, e in ipairs({ ... }) do
				if vim.tbl_islist(e) then
					vim.list_extend(args, e)
				else
					table.insert(args, e)
				end
			end
			return args
		end
	end

	return function()
		vim.notify("Not a git directory")
		return ""
	end
end

local cmd_with_default_args = function(cmd, opts)
	opts = opts or {}
	vim.validate({
		git_dir = { opts.git_dir, "s", true },
		no_color = { opts.no_color, "b", true },
	})
	local git_dir = opts.git_dir or vim.b.git_root or M.find_root()
	if opts.no_color then
		return git_dir and { "git", "--no-pager", "-C", git_dir, cmd } or nil
	else
		return git_dir and { "git", "--no-pager", "-c", "color.ui=always", "-C", git_dir, cmd } or nil
	end
end

function M.find_root()
	local res = vim.b.git_root or path.find_directory(".git")
	return res
end

function M.commit_message_file_path(git_dir)
	return ("%s/.git/COMMIT_EDITMSG"):format(git_dir)
end

function M.status_porcelain(file)
	local res = {}
	for _, line in ipairs(Job({ cmds = M.status("--porcelain", file) }):stdoutput()) do
		local state, old_filename, _, new_filename = unpack(line:split())
		res[old_filename] = {
			state = state,
			index = state:sub(1, 1),
			worktree = state:sub(2, 2),
		}
		if new_filename then
			res[new_filename] = {
				state = state,
				index = state:sub(1, 1),
				worktree = state:sub(2, 2),
			}
		end
	end
	return res
end

function M.with_default_args(opts)
	return setmetatable({}, {
		__index = function(_, cmd)
			return arg_strcat_factory(cmd_with_default_args(cmd, opts))
		end,
	})
end

setmetatable(M, {
	__index = function(_, cmd)
		return arg_strcat_factory(cmd_with_default_args(cmd))
	end,
})

return M
