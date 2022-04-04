local PipeParser = require("ivcs.libp.argparse.PipeParser")

describe("parse", function()
	it("Returns all args passed to it", function()
		local parser = PipeParser()
		assert.are.same(parser:parse("--flag a b --flag2 c"), { "--flag", "a", "b", "--flag2", "c" })
	end)
end)
