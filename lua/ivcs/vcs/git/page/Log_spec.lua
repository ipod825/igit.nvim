local a = require("plenary.async")
local describe = a.tests.describe
local it = a.tests.it
local igit = require("ivcs.vcs.git")
local util = require("ivcs.test_util")
local git = util.git
local test_dir = require("ivcs.vcs.git.TestDir")()
local path = require("ivcs.libp.path")
local log = require("ivcs.log")

describe("Log", function()
	igit.setup()
	local buffer_reload_waiter = util.BufReloadWaiter()

	-- todo: Use a.before_each after plenary#350
	before_each(a.util.will_block(function()
		local root = test_dir:refresh()
		vim.cmd(("edit %s"):format(path.join(root, test_dir.files[1])))
		igit.setup()
		igit.log:open()
		buffer_reload_waiter:wait()
		util.setrow(1)
	end))

	describe("parse_line", function()
		it("Parses the information of the lines", function() end)
	end)

	-- describe("switch", function()
	-- 	it("Switches the branch", function()
	-- 		util.setrow(2)
	-- 		igit.log:switch()
	-- 		assert.are.same(test_dir.path1[2], test_dir.current.branch())
	-- 		util.setrow(1)
	-- 		igit.log:switch()
	-- 		assert.are.same(test_dir.path1[1], test_dir.current.branch())
	-- 	end)
	-- end)
end)
