local List = require('igit.datatype.List')

describe("Constructor", function()
    it("Takes zero arguments", function()
        local l = List()
        assert.are.same(l, {})
    end)
end)

describe("append", function()
    it("Appends element", function()
        local l = List({1, 2})
        l:append(3)
        assert.are.same(l, {1, 2, 3})
    end)
end)

describe("extend", function()
    it("Extend list-like", function()
        local l = List({1, 2})
        l:extend({3, 4})
        assert.are.same(l, {1, 2, 3, 4})
        l:extend(List({5, 6}))
        assert.are.same(l, {1, 2, 3, 4, 5, 6})
    end)
end)

describe("Concat(_add)", function()
    it("Returns coancated list ", function()
        local l = List({1, 2})
        local l1 = l + {3, 4}
        local l2 = l1 + {5, 6}
        assert.are.same(l, {1, 2})
        assert.are.same(l1, {1, 2, 3, 4})
        assert.are.same(l2, {1, 2, 3, 4, 5, 6})
    end)
end)

describe("iterate", function()
    it("Iterates elements", function()
        local l = List({1, 2, 3, 4})
        local i = 1
        for e in l:values() do
            assert.are.equal(e, i)
            i = i + 1
        end
    end)
end)
