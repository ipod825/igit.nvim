local PipeParser = require("igit.libp.argparse.PipeParser")

describe("parse", function()
	it("Returns all args passed to it", function()
		local parser = PipeParser()
		assert.are.same({ "--flag", "a", "b", "--flag2", "c" }, parser:parse("--flag a b --flag2 c"))
	end)
end)
