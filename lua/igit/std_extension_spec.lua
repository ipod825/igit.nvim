require('igit.std_extension')

describe("std_extension", function()
    describe("find_str", function()
        it("Returns nil if no match", function()
            local a = "abc def ghi"
            assert.is_nil(a:find_str('defg'), nil)
        end)

        it("Finds matched string", function()
            local a = "abc def ghi"
            assert.are.equal(a:find_str('(def)'), 'def')
        end)
    end)
end)
