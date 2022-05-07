require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local describe = a.tests.describe
local Buffer = require("libp.ui.Buffer")
local igit = require("igit")
local util = require("igit.test_util")
local test_dir = require("igit.test_util.TestDir")(true)
local ui = require("libp.ui")
local Set = require("libp.datatype.Set")
local log = require("igit.log")

describe("Branch", function()
	igit.setup({ branch = { buf_enter_reload = false } })

	describe("open args", function()
		a.before_each(function()
			test_dir:refresh()
			vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
		end)

		a.it("Respects open_cmd", function()
			igit.branch:open(nil, "belowright split")
			ui.Buffer.get_current_buffer():reload()
			assert.same(2, #vim.api.nvim_tabpage_list_wins(0))
		end)

		a.it("Respects open_cmd", function()
			igit.branch:open(nil, "tabe")
			ui.Buffer.get_current_buffer():reload()
			assert.same(1, #vim.api.nvim_tabpage_list_wins(0))
		end)
	end)

	describe("functions", function()
		a.before_each(function()
			test_dir:refresh()
			vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
			igit.branch:open()
			ui.Buffer.get_current_buffer():reload()
			util.setrow(1)
		end)

		describe("parse_line", function()
			a.it("Parses the information of the lines", function()
				util.set_current_line("* branch-name Commit message (with paranthesis)")
				assert.are.same({ branch = "branch-name", is_current = true }, igit.branch:parse_line())
				util.set_current_line(" branch-name Commit message (with paranthesis)")
				assert.are.same({ branch = "branch-name", is_current = false }, igit.branch:parse_line())
				util.set_current_line("* (HEAD detached at a27b03661) a27b03661 Commit message (with paranthesis)")
				assert.are.same({ branch = "HEAD", is_current = true }, igit.branch:parse_line())
			end)
		end)

		describe("switch", function()
			a.it("Switches the branch", function()
				local function set_line_with_different_branch()
					local ori_branch = test_dir.current.branch()
					for i = 1, vim.fn.line("$") do
						local branch = igit.branch:parse_line(i).branch
						if branch and branch ~= ori_branch then
							util.setrow(i)
							return branch
						end
					end
				end

				local branch = set_line_with_different_branch()
				assert.are_not.same(branch, test_dir.current.branch())
				igit.branch:switch()
				assert.are.same(branch, test_dir.current.branch())

				branch = set_line_with_different_branch()
				assert.are_not.same(branch, test_dir.current.branch())
				igit.branch:switch()
				assert.are.same(branch, test_dir.current.branch())
			end)
		end)

		describe("rename", function()
			a.it("Renames branches", function()
				igit.branch:rename()
				vim.api.nvim_buf_set_lines(0, 0, 1, true, { util.new_name(test_dir.path1[1]) })
				vim.api.nvim_buf_set_lines(0, 1, 2, true, { util.new_name(test_dir.path1[2]) })
				vim.cmd("write")
				Buffer.get_current_buffer():wait_reload()
				assert.are.same(util.new_name(test_dir.path1[1]), test_dir.current.branch())
				assert.are.same({
					branch = util.new_name(test_dir.path1[1]),
					is_current = true,
				}, igit.branch:parse_line(1))
				assert.are.same({
					branch = util.new_name(test_dir.path1[2]),
					is_current = false,
				}, igit.branch:parse_line(2))
			end)
		end)

		describe("new_branch", function()
			a.it("Adds new branches", function()
				local ori_branches = Set(test_dir.current.branches())
				igit.branch:new_branch()
				local linenr = vim.fn.line(".") - 1
				local new_branch1 = util.new_name(test_dir.path1[1])
				local new_branch2 = util.new_name(test_dir.path1[2])
				local current_branch = test_dir.current.branch()
				vim.api.nvim_buf_set_lines(0, linenr, linenr, true, { new_branch1, new_branch2 })
				vim.cmd("write")
				Buffer.get_current_buffer():wait_reload()
				assert.are.same(test_dir.path1[1], current_branch)
				local new_branches = Set(test_dir.current.branches())
				assert.are.same(Set.size(ori_branches) + 2, Set.size(new_branches))
				assert.is_truthy(Set.has(new_branches, new_branch1))
				assert.is_truthy(Set.has(new_branches, new_branch2))

				assert.are.same(test_dir:get_sha(new_branch1), test_dir:get_sha(current_branch))
				assert.are.same(test_dir:get_sha(new_branch2), test_dir:get_sha(current_branch))
			end)

			a.it("Honors mark", function()
				vim.api.nvim_win_set_cursor(0, { 2, 0 })
				igit.branch:mark()
				igit.branch:new_branch()
				local linenr = vim.fn.line(".") - 1
				local new_branch2 = util.new_name(test_dir.path1[2])
				vim.api.nvim_buf_set_lines(0, linenr, linenr, true, { new_branch2 })
				vim.cmd("write")
				Buffer.get_current_buffer():wait_reload()
				assert.are.same(test_dir:get_sha(new_branch2), test_dir:get_sha(new_branch2))
			end)
		end)

		describe("force_delete_branch", function()
			a.it("Deletes branch in normal mode", function()
				local ori_branches = Set(test_dir.current.branches())
				igit.branch:force_delete_branch()
				assert.are.same(ori_branches, Set(test_dir.current.branches()))
				util.setrow(2)
				igit.branch:force_delete_branch()
				local new_branches = Set(test_dir.current.branches())
				assert.are.same(Set.size(ori_branches) - 1, Set.size(new_branches))
				assert.is_falsy(Set.has(new_branches, test_dir.path1[2]))
			end)

			a.it("Deletes branches in visual mode", function()
				local ori_branches = Set(test_dir.current.branches())
				vim.cmd("normal! Vj")
				igit.branch:force_delete_branch()
				local new_branches = Set(test_dir.current.branches())
				assert.are.same(Set.size(ori_branches) - 1, Set.size(new_branches))
				assert.is_falsy(Set.has(new_branches, test_dir.path1[2]))
			end)
		end)
	end)
end)
