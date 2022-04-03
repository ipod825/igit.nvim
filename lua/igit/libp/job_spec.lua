local job = require 'igit.libp.job'
local a = require('plenary.async')
local describe = a.tests.describe
local it = a.tests.it

describe("check_output", function()
    it("Returns  stdout string by default",
       function() assert.are.equal('a\nb', job.check_output('echo "a\nb"')) end)
    it("Returns list optionally", function()
        assert.are.same({'a', 'b'}, job.check_output('echo "a\nb"', true))
    end)
end)
