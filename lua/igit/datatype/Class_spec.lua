local Class = require('igit.datatype.Class')

local Derived = Class()
function Derived:init(num) self.num = num end

function Derived:inc(num) self.num = self.num + num end

describe("Constructor", function()
    it("Calls init", function()
        local d = Derived(1)
        assert.are.equal(d.num, 1)
        d:inc(1)
        assert.are.equal(d.num, 2)
    end)
end)

describe("bind", function()
    it("Binds self and arg", function()
        local d = Derived(1)
        local f = d:bind(d.inc, 1)
        f()
        assert.are.equal(d.num, 2)
    end)
end)