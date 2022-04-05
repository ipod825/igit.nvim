local M = require("ivcs.libp.datatype.Class"):EXTEND()
local path = require("ivcs.libp.path")
local Set = require("ivcs.libp.datatype.Set")
local job = require("ivcs.libp.job")
local a = require("plenary.async")
local git = require("ivcs.vcs.git.git")
local log = require("ivcs.log")
local ui = require("ivcs.libp.ui")

function M:open_or_new_buffer(key, opts)
	if opts.git_root == nil or opts.git_root == "" then
		vim.notify("No git project found!")
		return
	end

	if type(key) == "table" then
		key = table.concat(key, "")
	end

	vim.validate({
		key = { key, "string" },
		git_root = { opts.git_root, "string" },
		type = { opts.type, "string" },
	})

	self.buffer_index = self.buffer_index or Set()
	local index = Set.size(self.buffer_index)
	Set.add(self.buffer_index, key, (index == 0) and "" or tostring(index))

	opts = vim.tbl_deep_extend("force", {
		open_cmd = "tab drop",
		filename = ("ivcs://%s-%s%s"):format(path.basename(opts.git_root), opts.type, self.buffer_index[key]),
		b = { git_root = opts.git_root },
		bo = vim.tbl_extend("keep", opts.bo or {}, {
			filetype = "ivcs-" .. opts.type,
			bufhidden = "hide",
			buftype = "nofile",
			modifiable = false,
		}),
	}, opts)

	local buffer = ui.Buffer.open_or_new(opts)
	vim.cmd("lcd " .. opts.git_root)
	return buffer
end

function M:current_buf()
	return ui.Buffer.get_current_buffer()
end

function M:runasync_and_reload(cmd)
	local current_buf = self:current_buf()
	job.start(cmd)
	current_buf:reload()
end

function M:runasync_all_and_reload(cmds)
	local current_buf = self:current_buf()
	job.start_all(cmds)
	current_buf:reload()
end

function M:show(reference)
	vim.validate({ reference = { reference, "string" } })
	local grid = ui.Grid()
	grid:add_row({ height = 1 }):fill_window(ui.Window(ui.Buffer({ content = { reference } })))
	grid:add_row({ focusable = true }):fill_window(ui.Window(
		ui.Buffer({
			-- todo: with filetype equal to git, the floating window somehow
			-- shrink the height. Forking the syntax file to the ivcs folders
			-- does not have the same problem. Might be a neovim bug.
			bo = { filetype = "git_fork" },
			content = function()
				return git.with_default_args({ no_color = true }).show("%s"):format(reference)
			end,
		}),
		{ focus_on_open = true }
	))
	grid:show()
end

function M:rebase_branches(opts)
	vim.validate({
		branches = { opts.branches, "table" },
		current_buf = { opts.current_buf, "table" },
		grafted_ancestor = { opts.grafted_ancestor, "string" },
		base_reference = { opts.base_reference, "string" },
		ori_reference = { opts.ori_reference, "string" },
	})

	local grafted_ancestor = opts.grafted_ancestor
	local base_branch = opts.base_reference
	a.void(function()
		for _, new_branch in ipairs(opts.branches) do
			local next_grafted_ancestor = ("%s_original_conflicted_with_%s_created_by_ivcs"):format(
				new_branch,
				base_branch
			)
			job.start(git.branch(("%s %s"):format(next_grafted_ancestor, new_branch)))
			if grafted_ancestor ~= "" then
				local succ = 0
					== job.start(git.rebase(("--onto %s %s %s"):format(base_branch, grafted_ancestor, new_branch)))
				if grafted_ancestor:endswith("created_by_ivcs") then
					job.start(git.branch("-D " .. grafted_ancestor))
				end
				if not succ then
					opts.current_buf:reload()
					return
				end
			else
				if 0 ~= job.start(git.rebase(("%s %s"):format(base_branch, new_branch))) then
					job.start(git.branch("-D " .. next_grafted_ancestor))
					opts.current_buf:reload()
					return
				end
			end
			grafted_ancestor = next_grafted_ancestor
			base_branch = new_branch
		end
		job.start(git.branch("-D " .. grafted_ancestor))
		job.start(git.checkout(opts.ori_reference))
		opts.current_buf:reload()
	end)()
end

return M
