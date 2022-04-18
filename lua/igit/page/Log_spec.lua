local a = require("plenary.async")
local describe = a.tests.describe
local it = a.tests.it
local before_each = a.tests.before_each
local igit = require("igit")
local util = require("igit.test_util")
local test_dir = require("igit.test_util.TestDir")()
local ui = require("igit.libp.ui")
local Set = require("igit.libp.datatype.Set")
local Menu = require("igit.libp.ui.Menu")
local log = require("igit.log")

describe("Log", function()
	igit.setup({ log = { buf_enter_reload = false } })

	describe("open args", function()
		before_each(function()
			test_dir:refresh()
			vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
		end)

		it("Respects open_cmd", function()
			igit.log:open(nil, "belowright split")
			ui.Buffer.get_current_buffer():reload()
			assert.same(2, #vim.api.nvim_tabpage_list_wins(0))
		end)

		it("Respects open_cmd", function()
			igit.log:open(nil, "tabe")
			ui.Buffer.get_current_buffer():reload()
			assert.same(1, #vim.api.nvim_tabpage_list_wins(0))
		end)
	end)

	describe("functions", function()
		before_each(function()
			test_dir:refresh()
			vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
			igit.log:open()
			ui.Buffer.get_current_buffer():reload()
			util.setrow(1)
		end)

		describe("parse_line", function()
			it("Parses the information of the lines", function()
				util.set_current_line("* fa032ae (HEAD -> b1, b2, origin/b1) Commit message (with paranthesis)")
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
end)
