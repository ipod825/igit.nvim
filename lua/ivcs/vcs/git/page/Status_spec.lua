local a = require("plenary.async")
local describe = a.tests.describe
local it = a.tests.it
local igit = require("ivcs.vcs.git")
local util = require("ivcs.test_util")
local git = util.git
local test_dir = require("ivcs.vcs.git.TestDir")()
local path = require("ivcs.libp.path")
local log = require("ivcs.log")

igit.setup()
local buffer_reload_waiter = util.BufReloadWaiter()
local setup = function()
	local root = test_dir:refresh()
	vim.cmd(("edit %s"):format(path.path_join(root, test_dir.files[1])))
	igit.status:open()
	buffer_reload_waiter:wait()
	util.setrow(1)
end

describe("stage_change", function()
	it("Stages worktree file", function()
		setup()
		local fname = test_dir:touch_non_existing_file(1)
		igit.status.current_buf():reload()
		util.setrow(1)
		igit.status:stage_change()

		log.warn(fname)
		assert.are.same(fname, util.check_output("git diff --name-only --cached")[1])
	end)
end)
