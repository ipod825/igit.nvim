local igit = require("ivcs.vcs.git")

describe("igit", function()
	it("Sets up its submodules", function()
		igit.setup()
		assert.is_truthy(igit.log)
		assert.is_truthy(igit.branch)
		assert.is_truthy(igit.status)
	end)
end)
