local functional = require("igit.libp.functional")

describe("nop", function()
	it("Does nothing", function()
		functional.nop()
	end)
end)

describe("identity", function()
	it("Returns the argument", function()
		assert.are.same(1, functional.identity(1))
		assert.are.same(10, functional.identity(10))
	end)
end)

describe("head_tail", function()
	it("Returns the argument", function()
		local arr = { 1, 2, 3 }
		local head, tail = functional.head_tail(arr)
		assert.are.same(1, head)
		assert.are.same({ 2, 3 }, tail)
	end)
end)
