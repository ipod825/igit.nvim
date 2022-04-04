local List = require("ivcs.libp.datatype.List")
local Iterator = require("ivcs.libp.datatype.Iterator")

describe("Constructor", function()
	it("Takes zero arguments", function()
		local l = List()
		assert.are.same(l, {})
	end)
end)

describe("append", function()
	it("Appends element", function()
		local l = List({ 1, 2 })
		l:append(3)
		assert.are.same(l, { 1, 2, 3 })
	end)
end)

describe("extend", function()
	it("Extend list-like", function()
		local l = List({ 1, 2 })
		l:extend({ 3, 4 })
		assert.are.same(l, { 1, 2, 3, 4 })
		l:extend(List({ 5, 6 }))
		assert.are.same(l, { 1, 2, 3, 4, 5, 6 })
	end)
end)

describe("Concat(_add)", function()
	it("Returns coancated list ", function()
		local l = List({ 1, 2 })
		local l1 = l + { 3, 4 }
		local l2 = l1 + { 5, 6 }
		assert.are.same(l, { 1, 2 })
		assert.are.same(l1, { 1, 2, 3, 4 })
		assert.are.same(l2, { 1, 2, 3, 4, 5, 6 })
	end)
end)

describe("values", function()
	it("Iterates elements", function()
		local l = List({ 1, 2, 3, 4 })
		local i = 1
		for e in l:values() do
			assert.are.equal(e, i)
			i = i + 1
		end
	end)
end)

describe("map", function()
	it("Maps items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			l
				:map(function(e)
					return 2 * e
				end)
				:collect(),
			{ 2, 4, 6, 8 }
		)
	end)

	it("Maps items recursively", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			l
				:map(function(e)
					return 2 * e
				end)
				:map(function(e)
					return 2 * e
				end)
				:collect(),
			{ 4, 8, 12, 16 }
		)
	end)
end)

describe("filter", function()
	it("Filters items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			l
				:filter(function(e)
					return e % 2 == 0
				end)
				:collect(),
			{ 2, 4 }
		)
	end)
	it("Filters items recursively", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			l
				:filter(function(e)
					return e % 2 == 0
				end)
				:filter(function(e)
					return e > 2
				end)
				:collect(),
			{ 4 }
		)
	end)
end)

describe("filter map", function()
	it("Filters and maps items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			l
				:filter(function(e)
					return e % 2 == 0
				end)
				:map(function(e)
					return 1 * e
				end)
				:collect(),
			{ 2, 4 }
		)
	end)
	it("Maps and filters items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			l
				:map(function(e)
					return 2 * e
				end)
				:filter(function(e)
					return e < 6
				end)
				:collect(),
			{ 2, 4 }
		)
	end)
end)

describe("range", function()
	it("Defaults with step 1", function()
		assert.are.same(Iterator.range(1, 4):collect(), { 1, 2, 3, 4 })
	end)
	it("Supports customized step", function()
		assert.are.same(Iterator.range(1, 4, 2):collect(), { 1, 3 })
		assert.are.same(Iterator.range(1, 5, 2):collect(), { 1, 3, 5 })
	end)
	it("Can go from high to low", function()
		assert.are.same(Iterator.range(4, 1, -2):collect(), { 4, 2 })
		assert.are.same(Iterator.range(5, 1, -2):collect(), { 5, 3, 1 })
	end)
end)

describe("next", function()
	it("Yields next values", function()
		local iter = Iterator.range(1, 2)
		assert.are.same(iter:next(), 1)
		assert.are.same(iter:next(), 2)
		assert.are.same(iter:next(), nil)
	end)
	it("Modifies the internal of the iterators", function()
		local iter = Iterator.range(1, 3)
		assert.are.same(iter:next(), 1)
		assert.are.same(iter:collect(), { 2, 3 })
	end)
	it("Yields next values for List", function()
		local iter = List({ 1, 2 }):to_iter()
		assert.are.same(iter:next(), 1)
		assert.are.same(iter:next(), 2)
		assert.are.same(iter:next(), nil)
	end)
	it("Modifies the internal of the iterators for List", function()
		local iter = List({ 1, 2, 3 }):to_iter()
		assert.are.same(iter:next(), 1)
		assert.are.same(iter:collect(), { 2, 3 })
	end)
end)

describe("unbox_if_one", function()
	it("Returns 1st element if there's only one element", function()
		assert.are.same(List({ "a" }):unbox_if_one(), "a")
	end)
	it("Returns the list if there's multiple elements", function()
		local l = List({ "a", "b" })
		assert.are.same(l:unbox_if_one(), l)
	end)
end)
