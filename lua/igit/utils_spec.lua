local utils = require 'igit.utils'

describe("dirname", function()
    it("Returns parent for file",
       function() assert.are.equal(utils.dirname('a/b'), 'a') end)

    it("Returns directory for directory",
       function() assert.are.equal(utils.dirname('a/b/'), 'a/b') end)
end)

describe("basename", function()
    it("Works with file",
       function() assert.are.equal(utils.basename('a/b'), 'b') end)

    it("Works with directory",
       function() assert.are.equal(utils.basename('a/b/'), 'b') end)
end)

describe("path_join", function()
    it("joins the paths",
       function() assert.are.equal(utils.path_join('a', 'b'), 'a/b') end)
end)

describe("find_directory", function()
    it("Finds first parent of the anchor", function()
        local wdir = utils.dirname(vim.fn.tempname())
        local dir = wdir .. '/a/b/c/b/c'
        vim.fn.mkdir(dir, 'p')
        assert.are.equal(wdir .. '/a/b/c', utils.find_directory('b', dir))
    end)

    it("Finds from current file path by default", function()
        local wdir = utils.dirname(vim.fn.tempname())
        local dir = wdir .. '/a/b/c/b/c'
        vim.fn.mkdir(dir, 'p')
        vim.cmd('cd ' .. dir)
        vim.cmd('edit test_file')
        assert.are.equal(wdir .. '/a/b/c', utils.find_directory('b'))
    end)
end)
