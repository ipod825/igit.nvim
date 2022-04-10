local path = require("ivcs.libp.path")

describe("dirname", function()
	it("Returns parent for file", function()
		assert.are.same("a", path.dirname("a/b"))
	end)

	it("Returns directory for directory", function()
		assert.are.same("a/b", path.dirname("a/b/"))
	end)
end)

describe("basename", function()
	it("Works with file", function()
		assert.are.same("b", path.basename("a/b"))
	end)

	it("Works with directory", function()
		assert.are.same("b", path.basename("a/b/"))
	end)
end)

describe("join", function()
	it("Joins the paths", function()
		assert.are.same("a/b", path.join("a", "b"))
	end)
end)

describe("find_directory", function()
	it("Finds first parent of the anchor", function()
		local wdir = path.dirname(vim.fn.tempname())
		local dir = wdir .. "/a/b/c/b/c"
		vim.fn.mkdir(dir, "p")
		assert.are.same(wdir .. "/a/b/c", path.find_directory("b", dir))
	end)

	it("Finds from current file path by default", function()
		local wdir = path.dirname(vim.fn.tempname())
		local dir = wdir .. "/a/b/c/b/c"
		vim.fn.mkdir(dir, "p")
		vim.cmd("cd " .. dir)
		vim.cmd("edit test_file")
		assert.are.same(wdir .. "/a/b/c", path.find_directory("b"))
	end)
end)
