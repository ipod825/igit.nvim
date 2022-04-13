local List = require("igit.libp.datatype.List")
local Iterator = require("igit.libp.datatype.Iterator")

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

describe("map", function()
	it("Maps items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			{ 2, 4, 6, 8 },
			l
				:map(function(e)
					return 2 * e
				end)
				:collect()
		)
	end)

	it("Maps items recursively", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			{ 4, 8, 12, 16 },
			l
				:map(function(e)
					return 2 * e
				end)
				:map(function(e)
					return 2 * e
				end)
				:collect()
		)
	end)
end)

describe("filter", function()
	it("Filters items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			{ 2, 4 },
			l
				:filter(function(e)
					return e % 2 == 0
				end)
				:collect()
		)
	end)
	it("Filters items recursively", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			{ 4 },
			l
				:filter(function(e)
					return e % 2 == 0
				end)
				:filter(function(e)
					return e > 2
				end)
				:collect()
		)
	end)
end)

describe("filter map", function()
	it("Filters and maps items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			{ 2, 4 },
			l
				:filter(function(e)
					return e % 2 == 0
				end)
				:map(function(e)
					return 1 * e
				end)
				:collect()
		)
	end)
	it("Maps and filters items", function()
		local l = List({ 1, 2, 3, 4 })
		assert.are.same(
			{ 2, 4 },
			l
				:map(function(e)
					return 2 * e
				end)
				:filter(function(e)
					return e < 6
				end)
				:collect()
		)
	end)
end)

describe("range", function()
	it("Defaults with step 1", function()
		assert.are.same({ 1, 2, 3, 4 }, Iterator.range(1, 4):collect())
	end)
	it("Supports customized step", function()
		assert.are.same({ 1, 3 }, Iterator.range(1, 4, 2):collect())
		assert.are.same({ 1, 3, 5 }, Iterator.range(1, 5, 2):collect())
	end)
	it("Can go from high to low", function()
		assert.are.same({ 4, 2 }, Iterator.range(4, 1, -2):collect())
		assert.are.same({ 5, 3, 1 }, Iterator.range(5, 1, -2):collect())
	end)
end)

describe("next", function()
	it("Yields next values", function()
		local iter = Iterator.range(1, 2)
		assert.are.same(1, iter:next())
		assert.are.same(2, iter:next())
		assert.are.same(nil, iter:next())
	end)
	it("Modifies the internal of the iterators", function()
		local iter = Iterator.range(1, 3)
		assert.are.same(1, iter:next())
		assert.are.same({ 2, 3 }, iter:collect())
	end)
	it("Yields next values for List", function()
		local iter = List({ 1, 2 }):to_iter()
		assert.are.same(1, iter:next())
		assert.are.same(2, iter:next())
		assert.are.same(nil, iter:next())
	end)
	it("Modifies the internal of the iterators for List", function()
		local iter = List({ 1, 2, 3 }):to_iter()
		assert.are.same(1, iter:next())
		assert.are.same({ 2, 3 }, iter:collect())
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