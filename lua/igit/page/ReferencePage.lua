local M = require("igit.page.Page"):EXTEND()
local git = require("igit.git")
local ui = require("libp.ui")
local Job = require("libp.Job")
local values = require("libp.datatype.itertools").values

function M:show(reference)
	vim.validate({ reference = { reference, "s" } })
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
		or Job({ cmd = git["merge-base"](opts.base_reference, opts.branches[1]) }):stdoutputstr()
	excluded_base = Job({ cmd = git["name-rev"](excluded_base) }):stdoutputstr():split()[2]

	return "Yes"
		== ui.Menu({
			title = ("Rebasing onto %s"):format(opts.base_reference),
			content = {
				("(%s)->%s"):format(excluded_base, table.concat(opts.branches, "->")),
				"Tip: Check help page for skipping this confirmation.",
				"Yes",
				"No",
			},
			cursor_offset = { 0, math.floor(vim.o.columns / 3) },
		}):select()
end

function M:rebase_branches(opts)
	vim.validate({
		branches = { opts.branches, "t" },
		current_buf = { opts.current_buf, "t" },
		grafted_ancestor = { opts.grafted_ancestor, "s" },
		base_reference = { opts.base_reference, "s" },
		ori_reference = { opts.ori_reference, "string" },
	})

	if not self:confirm_rebase(opts) then
		return
	end

	local grafted_ancestor = opts.grafted_ancestor
	local base_branch = opts.base_reference

	for new_branch in values(opts.branches) do
		local next_grafted_ancestor = ("%s_original_conflicted_with_%s_created_by_igit"):format(new_branch, base_branch)
		Job({ cmd = git.branch(next_grafted_ancestor, new_branch) }):start()
		if grafted_ancestor ~= "" then
			local succ = 0 == Job({ cmd = git.rebase("--onto", base_branch, grafted_ancestor, new_branch) }):start()
			if vim.endswith(grafted_ancestor, "created_by_igit") then
				Job({ cmd = git.branch("-D", grafted_ancestor) }):start()
			end
			if not succ then
				opts.current_buf:reload()
				return
			end
		else
			if 0 ~= Job({ cmd = git.rebase(base_branch, new_branch) }):start() then
				Job({ cmd = git.branch("-D", next_grafted_ancestor) }):start()
				opts.current_buf:reload()
				return
			end
		end
		grafted_ancestor = next_grafted_ancestor
		base_branch = new_branch
	end
	Job({ cmd = git.branch("-D", grafted_ancestor) }):start()
	Job({ cmd = git.checkout(opts.ori_reference) }):start()
	opts.current_buf:reload()
end

return M
