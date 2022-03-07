require('igit.lib.datatype.std_extension')

describe("find_str", function()
    it("Returns nil if no match", function()
        local a = 'abc def ghi'
        assert.is_nil(a:find_str('defg'), nil)
    end)

    it("Finds matched string", function()
        local a = 'abc def ghi'
        assert.are.equal(a:find_str('(def)'), 'def')
    end)
end)

describe("split", function()
    it("Defaults to use space as delimiter", function()
        local a = 'abc def ghi'
        assert.are.same(a:split(), {'abc', 'def', 'ghi'})
    end)

    it("Returns array with splited string", function()
        local a = 'abc def ghi'
        assert.are.same(a:split(' '), {'abc', 'def', 'ghi'})
    end)

    it("Trims each element", function()
        local a = 'abc, def, ghi'
        assert.are.same(a:split(','), {'abc', 'def', 'ghi'})
    end)
end)

describe("trim", function()
    it("Trims spaces", function()
        local a = ' def '
        assert.are.same(a:trim(), 'def')
    end)
end)

describe("startswith", function()
    it("Returns true if the string starts with pattern", function()
        local a = 'abc def'
        assert.is_truthy(a:startswith('abc'))
        assert.is_falsy(a:startswith('def'))
    end)
end)

describe("endsswith", function()
    it("Returns true if the string endss with pattern", function()
        local a = 'abc def'
        assert.is_truthy(a:endswith('def'))
        assert.is_falsy(a:endswith('abc'))
    end)
end)
