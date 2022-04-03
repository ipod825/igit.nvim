local a = require('plenary.async')
local describe = a.tests.describe
local it = a.tests.it
local igit = require 'igit'
local test_dir = require 'igit.git.TestDir'()
local path = require 'igit.libp.path'
local log = require 'igit.log'

local setup = function()
    local root = test_dir:refresh()
    vim.cmd(('tabe %s'):format(path.path_join(root, test_dir.files[1])))
    igit.branch:open()
    -- todo: Not sure why we need this in order for job.start in open to finish
    -- starting from the second test.
    a.util.sleep(10)
end

describe("switch", function()
    it("Switches the branch", function()
        setup()
        vim.api.nvim_win_set_cursor(0, {2, 0})
        igit.branch:switch()
        assert.are.same(test_dir:current_branch(), test_dir.branches[2])
        vim.api.nvim_win_set_cursor(0, {1, 0})
        igit.branch:switch()
        assert.are.same(test_dir:current_branch(), test_dir.branches[1])
    end)

end)

describe("parse_line", function()
    it("Parses the information of the lines", function()
        setup()
        assert.are.same(igit.branch:parse_line(), igit.branch.parse_line(1))
        assert.are.same(igit.branch:parse_line(),
                        {branch = test_dir.branches[1], is_current = true})
        assert.are.same(igit.branch:parse_line(2),
                        {branch = test_dir.branches[2], is_current = false})
    end)
end)

describe("rename", function()
    it("Renames branches", function()
        setup()
        igit.branch:rename()
        local new_name = function(ori) return ori .. 'new' end
        vim.api.nvim_buf_set_lines(0, 0, 1, true,
                                   {new_name(test_dir.branches[1])})
        vim.api.nvim_buf_set_lines(0, 1, 2, true,
                                   {new_name(test_dir.branches[2])})
        vim.cmd('write')
        a.util.sleep(200)
        assert.are.same(test_dir:current_branch(),
                        new_name(test_dir.branches[1]))
        assert.are.same(igit.branch:parse_line(1), {
            branch = new_name(test_dir.branches[1]),
            is_current = true
        })
        assert.are.same(igit.branch:parse_line(2), {
            branch = new_name(test_dir.branches[2]),
            is_current = false
        })
    end)
end)
