require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local describe = a.tests.describe
local Buffer = require("libp.ui.Buffer")
local vimfn = require("libp.utils.vimfn")
local igit = require("igit")
local util = require("igit.test_util")
local git = util.git
local test_dir = require("igit.test_util.TestDir")()
local ui = require("libp.ui")
local vimfn = require("libp.utils.vimfn")
local Set = require("libp.datatype.Set")

describe("Status", function()
	igit.setup({ status = { buf_enter_reload = false } })

	describe("open args", function()
		a.before_each(function()
			test_dir:refresh()
			vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
		end)

		a.it("Respects open_cmd", function()
			igit.status:open(nil, "belowright split")
			ui.Buffer.get_current_buffer():reload()
			assert.same(2, #vim.api.nvim_tabpage_list_wins(0))
		end)

		a.it("Respects open_cmd", function()
			igit.status:open(nil, "tabe")
			ui.Buffer.get_current_buffer():reload()
			assert.same(1, #vim.api.nvim_tabpage_list_wins(0))
		end)
	end)

	describe("functions", function()
		a.before_each(function()
			test_dir:refresh()
			vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
			igit.status:open()
			ui.Buffer.get_current_buffer():reload()
			vimfn.setrow(1)
		end)

		describe("stage_change", function()
			a.it("Stages worktree file", function()
				local fname = test_dir:touch_untracked_file(1)
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				igit.status:stage_change()

				assert.are.same(fname, test_dir.current.staged_files()[1])
			end)

			a.it("Stages worktree file in visual mode", function()
				local fname1 = test_dir:touch_untracked_file(1)
				local fname2 = test_dir:touch_untracked_file(2)
				igit.status.current_buf():reload()

				vimfn.visual_select_rows(1, 2)
				igit.status:stage_change()

				assert.are.same({ fname1, fname2 }, test_dir.current.staged_files())
			end)
		end)

		describe("unstage_change", function()
			a.it("Unstages indexed file", function()
				local fname = test_dir:touch_untracked_file(1)
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				igit.status:stage_change()
				assert.are.same(fname, test_dir.current.staged_files()[1])
				igit.status:unstage_change()
				assert.are.same(0, #test_dir.current.staged_files())
			end)

			a.it("Unstages indexed file in visual mode", function()
				local fname1 = test_dir:touch_untracked_file(1)
				local fname2 = test_dir:touch_untracked_file(2)
				igit.status.current_buf():reload()

				vimfn.visual_select_rows(1, 2)
				igit.status:stage_change()

				assert.are.same({ fname1, fname2 }, test_dir.current.staged_files())

				igit.status:unstage_change()
				assert.are.same(0, #test_dir.current.staged_files())
			end)
		end)

		describe("discard_change", function()
			a.it("Discards worktree change", function()
				vimfn.setrow(1)
				util.jobrun("echo newline >> " .. test_dir.files[1])
				igit.status.current_buf():reload()
				assert.are.same(test_dir.files[1], test_dir.current.worktree_dirty_files()[1])

				igit.status:discard_change()
				assert.are.same(0, #test_dir.current.worktree_dirty_files())
			end)

			a.it("Discards worktree change in visual mode", function()
				vimfn.setrow(1)
				util.jobrun("echo newline >> " .. test_dir.files[1])
				util.jobrun("echo newline >> " .. test_dir.files[2])
				igit.status.current_buf():reload()
				assert.are.same(2, #test_dir.current.worktree_dirty_files())

				vimfn.visual_select_rows(1, 2)
				igit.status:discard_change()

				assert.are.same(0, #test_dir.current.worktree_dirty_files())
			end)
		end)

		describe("clean_files", function()
			a.it("Clean untracked file", function()
				local fname = test_dir:touch_untracked_file(1)
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				assert.are.same(fname, test_dir.current.worktree_untracked_files()[1])

				igit.status:clean_files()
				assert.are.same(0, #test_dir.current.worktree_untracked_files())
			end)

			a.it("Clean untracked file in visual mode", function()
				test_dir:touch_untracked_file(1)
				test_dir:touch_untracked_file(2)
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				assert.are.same(2, #test_dir.current.worktree_untracked_files())

				vimfn.visual_select_rows(1, 2)
				igit.status:clean_files()

				assert.are.same(0, #test_dir.current.worktree_untracked_files())
			end)
		end)

		describe("commit", function()
			a.it("Does not commit if no write", function()
				local fname = test_dir:touch_untracked_file(1)
				util.jobrun(git.add(fname))
				igit.status.current_buf():reload()
				vimfn.setrow(1)

				igit.status:commit()
				assert.are.same(test_dir:commit_message_file_path(), vim.api.nvim_buf_get_name(0))
				local commit_messages = { "test commit line1", "test commit line2" }
				vim.api.nvim_buf_set_lines(0, 0, -1, true, commit_messages)

				local ori_sha = test_dir:get_sha("HEAD")
				vim.cmd("bwipeout!")
				-- Wait long enough if there's any commit happening.
				a.util.sleep(500)

				assert.are.same(ori_sha, test_dir:get_sha("HEAD"))
			end)

			a.it("Commits change", function()
				local fname = test_dir:touch_untracked_file(1)
				util.jobrun(git.add(fname))
				igit.status.current_buf():reload()
				vimfn.setrow(1)

				igit.status:commit()
				assert.are.same(test_dir:commit_message_file_path(), vim.api.nvim_buf_get_name(0))
				local commit_messages = { "test commit line1", "test commit line2" }
				vim.api.nvim_buf_set_lines(0, 0, -1, true, commit_messages)

				local ori_sha = test_dir:get_sha("HEAD")
				local wait_commit = test_dir:wait_commit()
				vim.cmd("wq")
				wait_commit()

				local out_message = util.check_output(git.log("-n 1"))
				assert.are.same(commit_messages, vim.list_slice(out_message, #out_message - 1, #out_message))
				assert.are.same(ori_sha, test_dir:get_sha("HEAD^1"))
			end)

			a.it("Backup current branch if required", function()
				local fname = test_dir:touch_untracked_file(1)
				util.jobrun(git.add(fname))
				igit.status.current_buf():reload()
				vimfn.setrow(1)

				igit.status:commit({ backup_branch = true })
				assert.are.same(test_dir:commit_message_file_path(), vim.api.nvim_buf_get_name(0))
				local commit_messages = { "test commit line1", "test commit line2" }
				vim.api.nvim_buf_set_lines(0, 0, -1, true, commit_messages)

				local ori_branches = Set(test_dir.current.branches())

				local ori_sha = test_dir:get_sha("HEAD")
				local wait_commit = test_dir:wait_commit()
				vim.cmd("wq")
				wait_commit()

				assert.are.same(ori_sha, test_dir:get_sha("HEAD^1"))
				local backup_branch = Set(test_dir.current.branches()) - ori_branches
				assert.are.same(Set.size(backup_branch), 1)

				for b in Set.values(backup_branch) do
					assert.are.same(ori_sha, test_dir:get_sha(b))
				end
			end)

			a.it("Amends change", function()
				local fname = test_dir:touch_untracked_file(1)
				util.jobrun(git.add(fname))
				igit.status.current_buf():reload()
				vimfn.setrow(1)

				igit.status:commit({ amend = true })
				assert.are.same(test_dir:commit_message_file_path(), vim.api.nvim_buf_get_name(0))
				local commit_messages = { "test commit line1", "test commit line2" }
				vim.api.nvim_buf_set_lines(0, 0, -1, true, commit_messages)

				local ori_sha = test_dir:get_sha("HEAD")
				local ori_parent_sha = test_dir:get_sha("HEAD^1")
				local wait_commit = test_dir:wait_commit()
				vim.cmd("wq")
				wait_commit()

				local out_message = util.check_output(git.log("-n 1"))
				assert.are.same(commit_messages, vim.list_slice(out_message, #out_message - 1, #out_message))
				assert.are_not.same(ori_sha, test_dir:get_sha("HEAD"))
				assert.are.same(ori_parent_sha, test_dir:get_sha("HEAD^1"))
			end)
		end)

		describe("open", function()
			a.it("Opens file", function()
				local fname = test_dir:touch_untracked_file(1)
				util.jobrun(git.add(fname))
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				igit.status:open_file()
				assert.are.same(test_dir:abs_path(fname), vim.api.nvim_buf_get_name(0))
			end)

			a.it("Opens file with command", function()
				local fname = test_dir:touch_untracked_file(1)
				util.jobrun(git.add(fname))
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				igit.status:open_file("vsplit")
				assert.are.same(test_dir:abs_path(fname), vim.api.nvim_buf_get_name(0))
				assert.are.same(2, #vim.api.nvim_tabpage_list_wins(0))
			end)
		end)

		describe("diff_index", function()
			a.it("Diff against index.", function()
				local fname = test_dir.files[1]
				util.jobrun("echo newline >> " .. fname)
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				igit.status:diff_index()

				assert.is_truthy(#vim.api.nvim_tabpage_list_wins(0) >= 3)
				util.assert_diff_window_compaitability()

				vim.cmd("bwipeout")
				-- All diff windows should be closed together
				assert.are.same(1, #vim.api.nvim_tabpage_list_wins(0))
				util.jobrun(git.restor(fname))
			end)
		end)

		describe("diff_cached", function()
			a.it("Diff against stage. Staging all changes.", function()
				local fname = test_dir.files[1]
				util.jobrun("echo newline >> " .. fname)
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				igit.status:diff_cached()

				assert.is_truthy(#vim.api.nvim_tabpage_list_wins(0) >= 3)
				util.assert_diff_window_compaitability()

				-- This shouldn't be necessary as we run bwipeout elsewhere. But CI
				-- fails wihtout this. Not sure why.
				vim.cmd("edit")

				vim.cmd("1,$ diffput")
				vim.cmd("bwipeout")
				-- Wait on reload caused by BufEnter and Staging changes
				Buffer.get_current_buffer():wait_reload()

				-- All diff windows should be closed together
				assert.are.same(1, #vim.api.nvim_tabpage_list_wins(0))

				assert.are.same(fname, test_dir.current.staged_files()[1])
				assert.are.same(0, #test_dir.current.worktree_dirty_files())
			end)

			a.it("Diff against stage. Staging partial changes.", function()
				local fname = test_dir.files[1]
				util.jobrun('echo "newline\nknewline2" >> ' .. fname)
				igit.status.current_buf():reload()
				vimfn.setrow(1)
				igit.status:diff_cached()

				assert.is_truthy(#vim.api.nvim_tabpage_list_wins(0) >= 3)
				util.assert_diff_window_compaitability()

				vim.cmd(vim.api.nvim_buf_line_count(0) .. " diffput")
				vim.cmd("bwipeout")
				-- Wait on reload caused by BufEnter and Staging changes
				Buffer.get_current_buffer():wait_reload()

				-- All diff windows should be closed together
				assert.are.same(1, #vim.api.nvim_tabpage_list_wins(0))

				assert.are.same(fname, test_dir.current.staged_files()[1])
				assert.are.same(fname, test_dir.current.staged_files()[1])
				assert.are.same(fname, test_dir.current.worktree_dirty_files()[1])
			end)
		end)
	end)
end)
