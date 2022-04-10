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
			local fname = test_dir:touch_non_existing_file(1)
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:stage_change()

			assert.are.same(fname, util.check_output("git diff --name-only --cached")[1])
		end)

		it("Stages worktree file in visual mode", function()
			local fname1 = test_dir:touch_non_existing_file(1)
			local fname2 = test_dir:touch_non_existing_file(2)
			igit.status.current_buf():reload()

			local stub = util.VisualRowStub(1, 2)

			igit.status:stage_change()
			assert.are.same({ fname1, fname2 }, util.check_output("git diff --name-only --cached"))

			stub:revert()
		end)
	end)

	describe("unstage_change", function()
		it("Unstages indexed file", function()
			local fname = test_dir:touch_non_existing_file(1)
			igit.status.current_buf():reload()
			util.setrow(1)
			igit.status:stage_change()
			assert.are.same(fname, util.check_output("git diff --name-only --cached")[1])
			igit.status:unstage_change()
			assert.are.same(0, #util.check_output("git diff --name-only --cached"))
		end)

		it("Unstages indexed file in visual mode", function()
			local fname1 = test_dir:touch_non_existing_file(1)
			local fname2 = test_dir:touch_non_existing_file(2)
			igit.status.current_buf():reload()

			local stub = util.VisualRowStub(1, 2)

			igit.status:stage_change()
			assert.are.same({ fname1, fname2 }, util.check_output("git diff --name-only --cached"))

			igit.status:unstage_change()
			assert.are.same(0, #util.check_output("git diff --name-only --cached"))

			stub:revert()
		end)
	end)

	describe("discard_change", function()
		it("Discared worktree change", function()
			util.setrow(1)
			util.jobrun("echo newline >> " .. test_dir.files[1])
			igit.status.current_buf():reload()
			assert.are.same(test_dir.files[1], util.check_output("git diff --name-only")[1])

			igit.status:discard_change()
			assert.are.same(0, #util.check_output("git diff --name-only"))
		end)

		it("Discared worktree change in visual mode", function()
			util.setrow(1)
			util.jobrun("echo newline >> " .. test_dir.files[1])
			util.jobrun("echo newline >> " .. test_dir.files[2])
			igit.status.current_buf():reload()
			assert.are.same(2, #util.check_output("git diff --name-only"))

			local stub = util.VisualRowStub(1, 2)

			igit.status:discard_change()
			assert.are.same(0, #util.check_output("git diff --name-only"))

			stub:revert()
		end)
	end)
end)
