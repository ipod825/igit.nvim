local igit = require 'igit'

describe("igit", function()
    it("Sets up its submodules", function()
        assert.is_truthy(igit.log)
        assert.is_truthy(igit.branch)
        assert.is_truthy(igit.status)
    end)
end)
