local List = require("igit.libp.datatype.List")

describe("Constructor", function()
	it("Takes zero arguments", function()
		local l = List()
		assert.are.same({}, l)
	end)
end)

describe("append", function()
	it("Appends element", function()
		local l = List({ 1, 2 })
		l:append(3)
		assert.are.same({ 1, 2, 3 }, l)
	end)
end)

describe("extend", function()
	it("Extend list-like", function()
		local l = List({ 1, 2 })
		l:extend({ 3, 4 })
		assert.are.same({ 1, 2, 3, 4 }, l)
		l:extend(List({ 5, 6 }))
		assert.are.same({ 1, 2, 3, 4, 5, 6 }, l)
	end)
end)

describe("Concat(_add)", function()
	it("Returns concatenated list ", function()
		local l = List({ 1, 2 })
		local l1 = l + { 3, 4 }
		local l2 = l1 + { 5, 6 }
		assert.are.same({ 1, 2 }, l)
		assert.are.same({ 1, 2, 3, 4 }, l1)
		assert.are.same({ 1, 2, 3, 4, 5, 6 }, l2)
	end)
end)

describe("values", function()
	it("Iterates elements", function()
		local l = List({ 1, 2, 3, 4 })
		local i = 1
		for e in l:values() do
			assert.are.same(i, e)
			i = i + 1
		end
	end)
end)

describe("to_iter", function()
	it("Returns a IterList", function()
		local it = List({ 1, 2, 3, 4 }):to_iter()
		assert.are.same({ 1, 2, 3, 4 }, it:collect())
	end)
end)

describe("unbox_if_one", function()
	it("Returns 1st element if there's only one element", function()
		assert.are.same("a", List({ "a" }):unbox_if_one())
	end)
	it("Returns the list if there's multiple elements", function()
		local l = List({ "a", "b" })
		assert.are.same(l, l:unbox_if_one())
	end)
end)
