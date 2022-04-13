local a = require("plenary.async")
local describe = a.tests.describe
local it = a.tests.it
local igit = require("igit")
local util = require("igit.test_util")
local git = util.git
local test_dir = require("igit.TestDir")()
local path = require("igit.libp.path")
local Set = require("igit.libp.datatype.Set")
local Menu = require("igit.libp.ui.Menu")
local log = require("igit.log")

describe("Log", function()
	igit.setup()
	local buffer_reload_waiter = util.BufReloadWaiter()

	-- todo: Use a.before_each after plenary#350
	before_each(a.util.will_block(function()
		local root = test_dir:refresh()
		vim.cmd(("edit %s"):format(path.join(root, test_dir.files[1])))
		igit.setup()
		igit.log:open()
		-- Unlike the Branch and Status page,  buffer_reload_waiter:wait is not
		-- necessary as Log page defaults to wipe on hidden. So every open is a
		-- fresh open.
		util.setrow(1)
	end))

	describe("parse_line", function()
		it("Parses the information of the lines", function()
			local ori_line = util.set_current_line(
				"* fa032ae (HEAD -> b1, b2, origin/b1) Commit message (with paranthesis)"
			)
			local parsed = igit.log:parse_line()
			local expected = {
				sha = "fa032ae",
				branches = { "b1", "b2", "origin/b1" },
				references = {
					"b1",
					"b2",
					"origin/b1",
					"fa032ae",
				},
			}
			assert.are.same(expected.sha, parsed.sha)
			assert.are.equal(Set(expected.branches), Set(parsed.branches))
			assert.are.equal(Set(expected.references), Set(parsed.references))
		end)
	end)

	describe("switch", function()
		it("Switches the branch", function()
			local parsed = igit.log:parse_line()

			Menu.will_select_from_menu(function()
				assert.are.same(parsed.references, vim.api.nvim_buf_get_lines(0, 1, -1, true))
				util.setrow(2)
			end)

			assert.are_not.same(parsed.branches[1], test_dir.current.branch())
			igit.log:switch()
			assert.are.same(parsed.branches[1], test_dir.current.branch())
		end)
	end)

	describe("show", function()
		it("Shows a diff window", function()
			igit.log:show()
			assert.is_truthy(vim.api.nvim_win_get_config(0))
		end)
	end)
end)
