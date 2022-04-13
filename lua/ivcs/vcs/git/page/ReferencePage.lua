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
			bo = { filetype = "git" },
			content = function()
				return git.with_default_args({ no_color = true }).show(reference)
			end,
		}),
		{ focus_on_open = true }
	))
	grid:show()
end

function M:reset(current, target)
	local mode = ui.Menu({
		title = "Reset",
		content = {
			("--soft:  HEAD -> %s, Commit %s will be staged"):format(target, current),
			("--mixed: HEAD -> %s, Commit %s will be in worktree"):format(target, current),
			("--hard:  HEAD -> %s, Commit %s will be discarded"):format(target, current),
		},
	}):select()

	mode = mode:split(":")[1]
	if mode then
		self:runasync_and_reload(git.reset(mode, target))
	end
end

function M:confirm_rebase(opts)
	if not self.options.confirm_rebase then
		return true
	end

	local excluded_base = opts.grafted_ancestor ~= "" and opts.grafted_ancestor
		or job.check_output(git["merge-base"](opts.base_reference, opts.branches[1]))
	excluded_base = job.check_output(git["name-rev"](excluded_base)):split()[2]

	return "Yes"
		== ui.Menu({
			title = {
				("Rebasing onto %s"):format(opts.base_reference),
				("(%s)->%s"):format(excluded_base, table.concat(opts.branches, "->")),
				"Tip: Check help page for skipping this confirmation.",
			},
			content = {
				"Yes",
				"No",
			},
			cursor_offset = { 0, math.floor(vim.o.columns / 3) },
		}):select()
end

function M:rebase_branches(opts)
	vim.validate({
		branches = { opts.branches, "table" },
		current_buf = { opts.current_buf, "table" },
		grafted_ancestor = { opts.grafted_ancestor, "string" },
		base_reference = { opts.base_reference, "string" },
		ori_reference = { opts.ori_reference, "string" },
	})

	if not self:confirm_rebase(opts) then
		return
	end

	local grafted_ancestor = opts.grafted_ancestor
	local base_branch = opts.base_reference

	for _, new_branch in ipairs(opts.branches) do
		local next_grafted_ancestor = ("%s_original_conflicted_with_%s_created_by_ivcs"):format(new_branch, base_branch)
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
end

return M
