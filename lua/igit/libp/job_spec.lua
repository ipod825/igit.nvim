local Job = require("igit.libp.job")
local a = require("plenary.async")
local describe = a.tests.describe
local it = a.tests.it

describe("check_output", function()
	it("Returns  stdout string by default", function()
		assert.are.same("a\nb", Job({ cmds = { "echo", "a\nb" } }):check_output())
	end)
	it("Returns list optionally", function()
		assert.are.same({ "a", "b" }, Job({ cmds = { "echo", "a\nb" } }):check_output(true))
	end)
end)
