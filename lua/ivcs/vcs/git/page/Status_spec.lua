local a = require("plenary.async")
local describe = a.tests.describe
local it = a.tests.it
local igit = require("ivcs.vcs.git")
local util = require("ivcs.test_util")
local git = util.git
local test_dir = require("ivcs.vcs.git.TestDir")(true)
local path = require("ivcs.libp.path")
local log = require("ivcs.log")

describe("Status", function()
	igit.setup()
	local buffer_reload_waiter = util.BufReloadWaiter()

	-- todo: Use a.before_each after plenary#350
	before_each(a.util.will_block(function()
		local root = test_dir:refresh()
		vim.cmd(("edit %s"):format(path.path_join(root, test_dir.files[1])))
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
		it("Discared worktree change", function()
			util.setrow(1)
			util.jobrun("echo newline >> " .. test_dir.files[1])
			igit.status.current_buf():reload()
			assert.are.same(test_dir.files[1], test_dir.current.worktree_dirty_files()[1])

			igit.status:discard_change()
			assert.are.same(0, #test_dir.current.worktree_dirty_files())
		end)

		it("Discared worktree change in visual mode", function()
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
		it("commits change", function()
			local fname = test_dir:touch_untracked_file(1)
			util.jobrun(git.add(fname))
			igit.status.current_buf():reload()
			util.setrow(1)

			igit.status:commit()
			assert.are.same(test_dir:commit_message_file_path(), vim.api.nvim_buf_get_name(0))
			local commit_messages = { "test commit line1", "test commit line2" }
			vim.api.nvim_buf_set_lines(0, 0, 2, true, commit_messages)

			local wait_commit = test_dir:wait_commit()
			vim.cmd("wq")
			wait_commit()

			local out_message = util.check_output(git.log("-n 1"))
			assert.are.same(commit_messages, vim.list_slice(out_message, #out_message - 1, #out_message))
		end)
	end)
end)
