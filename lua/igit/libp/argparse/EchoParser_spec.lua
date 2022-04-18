local EchoParser = require("igit.libp.argparse.EchoParser")

describe("parse", function()
	it("Returns all args passed to it", function()
		local parser = EchoParser()
		assert.are.same({ { "", { "--flag", "a", "b", "--flag2", "c" } } }, parser:parse("--flag a b --flag2 c"))
	end)
end)
