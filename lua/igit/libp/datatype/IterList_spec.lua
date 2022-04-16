local IterList = require("igit.libp.datatype.IterList")

describe("map", function()
	it("Maps items", function()
		local l = IterList.from_range(1, 4)
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
		local l = IterList.from_range(1, 4)
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
		local l = IterList.from_range(1, 4)
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
		local l = IterList.from_range(1, 4)
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
		local l = IterList.from_range(1, 4)
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
		local l = IterList.from_range(1, 4)
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

describe("from_range", function()
	it("Defaults with step 1", function()
		assert.are.same({ 1, 2, 3, 4 }, IterList.from_range(1, 4):collect())
	end)
	it("Supports customized step", function()
		assert.are.same({ 1, 3 }, IterList.from_range(1, 4, 2):collect())
		assert.are.same({ 1, 3, 5 }, IterList.from_range(1, 5, 2):collect())
	end)
	it("Can go from high to low", function()
		assert.are.same({ 4, 2 }, IterList.from_range(4, 1, -2):collect())
		assert.are.same({ 5, 3, 1 }, IterList.from_range(5, 1, -2):collect())
	end)
end)

describe("next", function()
	it("Yields next values", function()
		local iter = IterList.from_range(1, 2)
		assert.are.same(1, iter:next())
		assert.are.same(2, iter:next())
		assert.are.same(nil, iter:next())
	end)
	it("Modifies the internal of the iterators", function()
		local iter = IterList.from_range(1, 3)
		assert.are.same(1, iter:next())
		assert.are.same({ 2, 3 }, iter:collect())
	end)
	it("Yields next values for List", function()
		local iter = IterList.from_range(1, 2)
		assert.are.same(1, iter:next())
		assert.are.same(2, iter:next())
		assert.are.same(nil, iter:next())
	end)
	it("Modifies the internal of the iterators for List", function()
		local iter = IterList.from_range(1, 3)
		assert.are.same(1, iter:next())
		assert.are.same({ 2, 3 }, iter:collect())
	end)
end)
