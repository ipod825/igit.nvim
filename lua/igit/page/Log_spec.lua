require("plenary.async").tests.add_to_env()
local a = require("plenary.async")
local describe = a.tests.describe
local igit = require("igit")
local util = require("igit.test_util")
local test_dir = require("igit.test_util.TestDir")()
local ui = require("libp.ui")
local Set = require("libp.datatype.Set")
local Menu = require("libp.ui.Menu")
local vimfn = require("libp.utils.vimfn")

describe("Log", function()
    igit.setup({ log = { buf_enter_reload = false } })

    describe("open args", function()
        a.before_each(function()
            test_dir:refresh()
            vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
        end)

        a.it("Respects open_cmd", function()
            igit.log:open(nil, "belowright split")
            ui.Buffer.get_current_buffer():reload()
            assert.same(2, #vim.api.nvim_tabpage_list_wins(0))
        end)

        a.it("Respects open_cmd", function()
            igit.log:open(nil, "tabe")
            ui.Buffer.get_current_buffer():reload()
            assert.same(1, #vim.api.nvim_tabpage_list_wins(0))
        end)
    end)

    describe("functions", function()
        a.before_each(function()
            test_dir:refresh()
            vim.cmd(("edit %s"):format(test_dir:abs_path(test_dir.files[1])))
            igit.log:open()
            ui.Buffer.get_current_buffer():reload()
            vimfn.setrow(1)
        end)

        describe("parse_line", function()
            a.it("Parses the information of the lines", function()
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
            a.it("Switches the branch", function()
                local parsed = igit.log:parse_line()

                Menu.will_select_from_menu(function()
                    assert.are.same(parsed.references, vimfn.buf_get_lines())
                    return 1
                end)

                assert.are_not.same(parsed.branches[1], test_dir.current.branch())
                igit.log:switch()
                assert.are.same(parsed.branches[1], test_dir.current.branch())
            end)
        end)

        describe("show", function()
            a.it("Shows a diff window", function()
                igit.log:show()
                assert.is_truthy(vim.api.nvim_win_get_config(0))
            end)
        end)

        describe("yank_sha", function()
            a.it("Yanks the current sha to the anonymous register", function()
                igit.log:yank_sha()
                assert.are.same(vim.fn.getreg('"'), igit.log:parse_line().sha)
            end)
        end)
    end)
end)
