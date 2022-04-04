local a = require('plenary.async')
local describe = a.tests.describe
local it = a.tests.it
local igit = require 'igit'
local util = require 'igit.test_util'
local git = util.git
local test_dir = require 'igit.test_util.TestDir'()
local path = require 'igit.libp.path'
local Set = require 'igit.libp.datatype.Set'
local log = require 'igit.log'

local reload_done
local setup = function()
    local root = test_dir:refresh()
    vim.cmd(('edit %s'):format(path.path_join(root, test_dir.files[1])))
    igit.branch:open()
    if reload_done == nil then
        reload_done = igit.branch:current_buf():register_reload_notification()
    else
        reload_done:wait()
    end
    util.setrow(1)
end

local function new_name(ori) return ori .. 'new' end

describe("switch", function()
    it("Switches the branch", function()
        setup()
        util.setrow(2)
        igit.branch:switch()
        assert.are.same(test_dir:current_branch(), test_dir.path1[2])
        util.setrow(1)
        igit.branch:switch()
        assert.are.same(test_dir:current_branch(), test_dir.path1[1])
    end)
end)

describe("parse_line", function()
    it("Parses the information of the lines", function()
        setup()
        assert.are.same(igit.branch:parse_line(), igit.branch.parse_line(1))
        assert.are.same(igit.branch:parse_line(),
                        {branch = test_dir.path1[1], is_current = true})
        assert.are.same(igit.branch:parse_line(2),
                        {branch = test_dir.path1[2], is_current = false})
    end)
end)

describe("rename", function()
    it("Renames branches", function()
        setup()
        igit.branch:rename()
        vim.api.nvim_buf_set_lines(0, 0, 1, true, {new_name(test_dir.path1[1])})
        vim.api.nvim_buf_set_lines(0, 1, 2, true, {new_name(test_dir.path1[2])})
        vim.cmd('write')
        reload_done:wait()
        assert.are.same(test_dir:current_branch(), new_name(test_dir.path1[1]))
        assert.are.same(igit.branch:parse_line(1), {
            branch = new_name(test_dir.path1[1]),
            is_current = true
        })
        assert.are.same(igit.branch:parse_line(2), {
            branch = new_name(test_dir.path1[2]),
            is_current = false
        })
    end)
end)

describe("new_branch", function()
    it("Adds new branches", function()
        setup()
        local ori_branches = Set(test_dir:branches())
        igit.branch:new_branch()
        local linenr = vim.fn.line('.') - 1
        local new_branch1 = new_name(test_dir.path1[1])
        local new_branch2 = new_name(test_dir.path1[2])
        local current_branch = test_dir:current_branch()
        vim.api.nvim_buf_set_lines(0, linenr, linenr, true,
                                   {new_branch1, new_branch2})
        vim.cmd('write')
        reload_done:wait()
        assert.are.same(current_branch, test_dir.path1[1])
        local new_branches = Set(test_dir:branches())
        assert.are.same(Set.size(new_branches), Set.size(ori_branches) + 2)
        assert.is_truthy(Set.has(new_branches, new_branch1))
        assert.is_truthy(Set.has(new_branches, new_branch2))

        assert.are.same(util.check_output(git['rev-parse'](current_branch)),
                        util.check_output(git['rev-parse'](new_branch1)))
        assert.are.same(util.check_output(git['rev-parse'](current_branch)),
                        util.check_output(git['rev-parse'](new_branch2)))
    end)

    it("Hononrs mark", function()
        vim.api.nvim_win_set_cursor(0, {2, 0})
        igit.branch:mark()
        igit.branch:new_branch()
        local linenr = vim.fn.line('.') - 1
        local new_branch2 = new_name(test_dir.path1[2])
        vim.api.nvim_buf_set_lines(0, linenr, linenr, true, {new_branch2})
        vim.cmd('write')
        reload_done:wait()
        assert.are.same(util.check_output(git['rev-parse'](new_branch2)),
                        util.check_output(git['rev-parse'](new_branch2)))
    end)
end)

describe("force_delete_branch", function()
    it("Deletes branch in normal mode", function()
        setup()
        local ori_branches = Set(test_dir:branches())
        igit.branch:force_delete_branch()
        assert.are.equal(ori_branches, Set(test_dir:branches()))
        util.setrow(2)
        igit.branch:force_delete_branch()
        local new_branches = Set(test_dir:branches())
        assert.are.equal(Set.size(new_branches), Set.size(ori_branches) - 1)
        assert.is_falsy(Set.has(new_branches, test_dir.path1[2]))
    end)

    it("Delete branches in visual mode", function()
        setup()
        local ori_branches = Set(test_dir:branches())
        vim.cmd('normal! Vj')
        igit.branch:force_delete_branch()
        local new_branches = Set(test_dir:branches())
        assert.are.equal(Set.size(new_branches), Set.size(ori_branches) - 1)
        assert.is_falsy(Set.has(new_branches, test_dir.path1[2]))
    end)
end)
