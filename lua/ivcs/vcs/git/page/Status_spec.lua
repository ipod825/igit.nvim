local a = require("plenary.async")
local describe = a.tests.describe
local it = a.tests.it
local igit = require("ivcs.vcs.git")
local util = require("ivcs.test_util")
local git = util.git
local test_dir = require("ivcs.vcs.git.TestDir")()
local path = require("ivcs.libp.path")
local Set = require("ivcs.libp.datatype.Set")
local log = require("ivcs.log")

describe("Status", function()
	igit.setup()
	local buffer_reload_waiter = util.BufReloadWaiter()

	-- todo: Use a.before_each after plenary#350
	before_each(a.util.will_block(function()
		test_dir:refresh()
		vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
		igit.status:open()
		buffer_reload_waiter:wait()
		util.setrow(1)
	end))

	describe("stage_change", function()
		it("Stages worktree file", function()
			local fname = test_dir:touch_untracked_file(1)
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:stage_change()

			assert.are.same(fname, test_dir.current.staged_files()[1])
		end)

		it("Stages worktree file in visual mode", function()
			local fname1 = test_dir:touch_untracked_file(1)
			local fname2 = test_dir:touch_untracked_file(2)
			igit.status.current_buf():reload()

			local stub = util.VisualRowStub(1, 2)

			igit.status:stage_change()
			assert.are.same({ fname1, fname2 }, test_dir.current.staged_files())

			stub:revert()
		end)
	end)

	describe("unstage_change", function()
		it("Unstages indexed file", function()
			local fname = test_dir:touch_untracked_file(1)
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:stage_change()
			assert.are.same(fname, test_dir.current.staged_files()[1])
			igit.status:unstage_change()
			assert.are.same(0, #test_dir.current.staged_files())
		end)

		it("Unstages indexed file in visual mode", function()
			local fname1 = test_dir:touch_untracked_file(1)
			local fname2 = test_dir:touch_untracked_file(2)
			igit.status.current_buf():reload()

			local stub = util.VisualRowStub(1, 2)

			igit.status:stage_change()
			assert.are.same({ fname1, fname2 }, test_dir.current.staged_files())

			igit.status:unstage_change()
			assert.are.same(0, #test_dir.current.staged_files())

			stub:revert()
		end)
	end)

	describe("discard_change", function()
		it("Discards worktree change", function()
			util.setrow(1)
			util.jobrun("echo newline >> " .. test_dir.files[1])
			igit.status.current_buf():reload()
			assert.are.same(test_dir.files[1], test_dir.current.worktree_dirty_files()[1])

			igit.status:discard_change()
			assert.are.same(0, #test_dir.current.worktree_dirty_files())
		end)

		it("Discards worktree change in visual mode", function()
			util.setrow(1)
			util.jobrun("echo newline >> " .. test_dir.files[1])
			util.jobrun("echo newline >> " .. test_dir.files[2])
			igit.status.current_buf():reload()
			assert.are.same(2, #test_dir.current.worktree_dirty_files())

			local stub = util.VisualRowStub(1, 2)

			igit.status:discard_change()
			assert.are.same(0, #test_dir.current.worktree_dirty_files())

			stub:revert()
		end)
	end)

	describe("clean_files", function()
		it("Clean untracked file", function()
			local fname = test_dir:touch_untracked_file(1)
			igit.status.current_buf():reload()
			util.setrow(1)
			assert.are.same(fname, test_dir.current.worktree_untracked_files()[1])

			igit.status:clean_files()
			assert.are.same(0, #test_dir.current.worktree_untracked_files())
		end)

		it("Clean untracked file in visual mode", function()
			test_dir:touch_untracked_file(1)
			test_dir:touch_untracked_file(2)
			igit.status.current_buf():reload()
			util.setrow(1)
			assert.are.same(2, #test_dir.current.worktree_untracked_files())

			local stub = util.VisualRowStub(1, 2)

			igit.status:clean_files()
			assert.are.same(0, #test_dir.current.worktree_untracked_files())

			stub:revert()
		end)
	end)

	describe("commit", function()
		it("Does not commit if no write", function()
			local fname = test_dir:touch_untracked_file(1)
			util.jobrun(git.add(fname))
			igit.status.current_buf():reload()
			util.setrow(1)

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

		it("Commits change", function()
			local fname = test_dir:touch_untracked_file(1)
			util.jobrun(git.add(fname))
			igit.status.current_buf():reload()
			util.setrow(1)

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

		it("Backup current branch if required", function()
			local fname = test_dir:touch_untracked_file(1)
			util.jobrun(git.add(fname))
			igit.status.current_buf():reload()
			util.setrow(1)

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

		it("Amends change", function()
			local fname = test_dir:touch_untracked_file(1)
			util.jobrun(git.add(fname))
			igit.status.current_buf():reload()
			util.setrow(1)

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
		it("Opens file", function()
			local fname = test_dir:touch_untracked_file(1)
			util.jobrun(git.add(fname))
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:open_file()
			assert.are.same(test_dir:abs_path(fname), vim.api.nvim_buf_get_name(0))
		end)

		it("Opens file with command", function()
			local fname = test_dir:touch_untracked_file(1)
			util.jobrun(git.add(fname))
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:open_file("vsplit")
			assert.are.same(test_dir:abs_path(fname), vim.api.nvim_buf_get_name(0))
			assert.are.same(2, #vim.api.nvim_tabpage_list_wins(0))
		end)
	end)

	describe("diff_cached", function()
		it("Diff against index.", function()
			local fname = test_dir.files[1]
			util.jobrun("echo newline >> " .. fname)
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:diff_index()

			assert.is_truthy(#vim.api.nvim_tabpage_list_wins(0) >= 3)
			util.assert_diff_window_compaitability()

			vim.cmd("bwipeout")
			-- Wait on reload caused by BufEnter
			buffer_reload_waiter:wait()

			-- All diff windows should be closed together
			assert.are.same(1, #vim.api.nvim_tabpage_list_wins(0))
			util.jobrun(git.restor(fname))
		end)
	end)

	describe("diff_cached", function()
		it("Diff against stage. Staging all changes.", function()
			local fname = test_dir.files[1]
			util.jobrun("echo newline >> " .. fname)
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:diff_cached()

			assert.is_truthy(#vim.api.nvim_tabpage_list_wins(0) >= 3)
			util.assert_diff_window_compaitability()

			assert.are.same(2, vim.api.nvim_buf_line_count(0))

			assert.are.same({ "path 1 file 1 line 1", "newline" }, vim.api.nvim_buf_get_lines(0, 0, -1, true))

			vim.cmd("1,$ diffput")
			vim.cmd("bwipeout")
			-- Wait on reload caused by BufEnter and Staging changes
			buffer_reload_waiter:wait(2)

			-- All diff windows should be closed together
			assert.are.same(1, #vim.api.nvim_tabpage_list_wins(0))

			assert.are.same(fname, test_dir.current.staged_files()[1])
			assert.are.same(0, #test_dir.current.worktree_dirty_files())
		end)

		it("Diff against stage. Staging partial changes.", function()
			local fname = test_dir.files[1]
			util.jobrun('echo "newline\nknewline2" >> ' .. fname)
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:diff_cached()

			assert.is_truthy(#vim.api.nvim_tabpage_list_wins(0) >= 3)
			util.assert_diff_window_compaitability()

			vim.cmd(vim.api.nvim_buf_line_count(0) .. " diffput")
			vim.cmd("bwipeout")
			-- Wait on reload caused by BufEnter and Staging changes
			buffer_reload_waiter:wait(2)

			-- All diff windows should be closed together
			assert.are.same(1, #vim.api.nvim_tabpage_list_wins(0))

			assert.are.same(fname, test_dir.current.staged_files()[1])
			assert.are.same(fname, test_dir.current.staged_files()[1])
			assert.are.same(fname, test_dir.current.worktree_dirty_files()[1])
		end)
	end)
end)
