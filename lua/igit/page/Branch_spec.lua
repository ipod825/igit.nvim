local a = require('plenary.async')
local describe = a.tests.describe
local it = a.tests.it
local igit = require 'igit'
local test_dir = require 'igit.git.TestDir'()
local path = require 'igit.libp.path'
local log = require 'igit.log'

local refresh = function()
    local root = test_dir:refresh()
    vim.cmd(('edit %s'):format(path.path_join(root, test_dir.files[1])))
end

describe("switch", function()
    it("Switches the branch", function()
        refresh()
        igit.branch:open()
        vim.api.nvim_win_set_cursor(0, {2, 0})
        igit.branch:switch()
        assert.are.same(test_dir:current_branch(), test_dir.branches[2])
    end)
end)

-- describe("Rename", function()
--     it("Rename branches", function()
--         refresh()
--         igit.branch:rename()
--         vim.api.nvim_win_set_cursor(0, {2, 0})
--         igit.branch:switch()
--         assert.are.same(test_dir:current_branch(), test_dir.branches[2])
--     end)
-- end)
