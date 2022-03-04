local List = require('igit.ds.List')

describe("List", function()
    it("Takes zero arguments", function()
        local l = List()
        assert.are.same(l, {})
    end)

    it("Appends element", function()
        local l = List({1, 2})
        l:append(3)
        assert.are.same(l, {1, 2, 3})
    end)

    it("Extend list-like", function()
        local l = List({1, 2})
        l:extend({3, 4})
        assert.are.same(l, {1, 2, 3, 4})
        l:extend(List({5, 6}))
        assert.are.same(l, {1, 2, 3, 4, 5, 6})
    end)

    it("Iterates elements", function()
        local l = List({1, 2, 3, 4})
        local i = 1
        for e in l:iter() do
            assert.are.equal(e, i)
            i = i + 1
        end
    end)

    it("Enumerates indices and elements", function()
        local l = List({1, 2, 3, 4})
        for i, e in l:enumerate() do assert.are.equal(e, i) end
    end)
end)
