local M = require("ivcs.vcs.git.page.Page"):EXTEND()
local a = require("plenary.async")
local git = require("ivcs.vcs.git.git")
local ui = require("ivcs.libp.ui")
local job = require("ivcs.libp.job")

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
				return git.with_default_args({ no_color = true }).show(reference)
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
			job.start(git.branch(next_grafted_ancestor, new_branch))
			if grafted_ancestor ~= "" then
				local succ = 0 == job.start(git.rebase("--onto", base_branch, grafted_ancestor, new_branch))
				if grafted_ancestor:endswith("created_by_ivcs") then
					job.start(git.branch("-D", grafted_ancestor))
				end
				if not succ then
					opts.current_buf:reload()
					return
				end
			else
				if 0 ~= job.start(git.rebase(base_branch, new_branch)) then
					job.start(git.branch("-D", next_grafted_ancestor))
					opts.current_buf:reload()
					return
				end
			end
			grafted_ancestor = next_grafted_ancestor
			base_branch = new_branch
		end
		job.start(git.branch("-D", grafted_ancestor))
		job.start(git.checkout(opts.ori_reference))
		opts.current_buf:reload()
	end)()
end

return M
