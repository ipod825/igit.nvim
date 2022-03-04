local List = require('igit.datatype.List')

<<<<<<< HEAD
describe("List", function()
=======
describe("Constructor", function()
>>>>>>> 7fe4fb3 (Start adding tests.)
    it("Takes zero arguments", function()
        local l = List()
        assert.are.same(l, {})
    end)
<<<<<<< HEAD

=======
end)

describe("append", function()
>>>>>>> 7fe4fb3 (Start adding tests.)
    it("Appends element", function()
        local l = List({1, 2})
        l:append(3)
        assert.are.same(l, {1, 2, 3})
    end)
<<<<<<< HEAD

=======
end)

describe("extend", function()
>>>>>>> 7fe4fb3 (Start adding tests.)
    it("Extend list-like", function()
        local l = List({1, 2})
        l:extend({3, 4})
        assert.are.same(l, {1, 2, 3, 4})
        l:extend(List({5, 6}))
        assert.are.same(l, {1, 2, 3, 4, 5, 6})
    end)
<<<<<<< HEAD

=======
end)

describe("iterate", function()
>>>>>>> 7fe4fb3 (Start adding tests.)
    it("Iterates elements", function()
        local l = List({1, 2, 3, 4})
        local i = 1
        for e in l:iter() do
            assert.are.equal(e, i)
            i = i + 1
        end
    end)
<<<<<<< HEAD

=======
end)

describe("enumerate", function()
>>>>>>> 7fe4fb3 (Start adding tests.)
    it("Enumerates indices and elements", function()
        local l = List({1, 2, 3, 4})
        for i, e in l:enumerate() do assert.are.equal(e, i) end
    end)
end)
