local Class = require("igit.libp.datatype.Class")

local Child
local GrandChild

describe("Class", function()
	before_each(function()
		Child = Class:EXTEND()
		GrandChild = Child:EXTEND()
	end)
	describe("EXTEND", function()
		it("Adds call and index to metatable", function()
			ChildMt = getmetatable(Child)
			assert.is_truthy(ChildMt.__call)
			assert.is_truthy(ChildMt.__index, ChildMt)

			GrandChildMt = getmetatable(GrandChild)
			assert.is_truthy(ChildMt.__call)
			assert.is_truthy(GrandChildMt.__index, GrandChildMt)
		end)

		it("Supports inheritance", function()
			function Child:fn(arg)
				return "Child" .. arg
			end
			assert.are.same("Childarg", Child():fn("arg"))
			assert.are.same("Childarg", GrandChild():fn("arg"))
		end)

		it("Supports override", function()
			function Child:fn(arg)
				return "Child" .. arg
			end
			function GrandChild:fn(arg)
				return "GrandChild" .. arg
			end
			assert.are.same("Childarg", Child():fn("arg"))
			assert.are.same("GrandChildarg", GrandChild():fn("arg"))
		end)
	end)

	describe("Constructor (__call)", function()
		it("Has default initializer", function()
			assert.is_truthy(Child())
			assert.is_truthy(GrandChild())
		end)

		it("Calls parent init", function()
			function Child:init(num)
				self.num = num
			end
			assert.are.same(1, Child(1).num)
			assert.are.same(1, GrandChild(1).num)
		end)

		it("Calls own init", function()
			function Child:init(num)
				self.num = num
			end
			function GrandChild:init(num)
				self.num = 2 * num
			end
			assert.are.same(1, Child(1).num)
			assert.are.same(2, GrandChild(1).num)
		end)
	end)

	describe("BIND", function()
		it("Binds self and arg", function()
			function Child:init()
				self.num = 1
			end
			function Child:add(a, b)
				self.num = self.num + a + b
				return self.num
			end
			local c = Child()
			local f = c:BIND(c.add, 1)
			assert.are.same(4, f(2))
			assert.are.same(4, c.num)

			local c2 = Child()
			local ff = c2:BIND(c2.add, 2, 3)
			assert.are.same(6, ff())
			assert.are.same(6, c2.num)
		end)

		it("Binds args by reference", function()
			function Child:append(arr, e)
				table.insert(arr, e)
			end
			local arr = {}
			local c = Child()
			local f = c:BIND(c.append, arr)
			f(1)
			assert.are.same({ 1 }, arr)
			f(2)
			assert.are.same({ 1, 2 }, arr)
		end)
	end)

	describe("SUPER", function()
		it("Calls parent's method", function()
			function Child:init()
				self.num = 1
			end
			function GrandChild:init()
				self.num = 2
			end

			function Child:fn()
				return "Child" .. self.num
			end

			function GrandChild:fn()
				return "GrandChild" .. self.num
			end

			local d2 = GrandChild()
			assert.are.same("GrandChild2", d2:fn())
			assert.are.same("Child2", d2:SUPER():fn())
		end)
	end)
end)
