local Class = require("igit.libp.datatype.Class")

local Derived = Class()
function Derived:init(num)
	self.num = num
end

function Derived:inc(num)
	self.num = self.num + num
end

describe("Constructor", function()
	it("Calls init", function()
		local d = Derived(1)
		assert.are.same(1, d.num)
		d:inc(1)
		assert.are.same(2, d.num)
	end)
end)

describe("bind", function()
	it("Binds self and arg", function()
		local d = Derived(1)
		local f = d:BIND(d.inc, 1)
		f()
		assert.are.same(2, d.num)
	end)
end)
