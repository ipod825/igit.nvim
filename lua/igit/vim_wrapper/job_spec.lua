local job = require 'igit.vim_wrapper.job'

describe("popen", function()
    it("Returns  stdout string by default",
       function() assert.are.equal('a\nb', job.popen('echo "a\nb"')) end)
    it("Returns list optionally", function()
        assert.are.same({'a', 'b'}, job.popen('echo "a\nb"', true))
    end)
end)
