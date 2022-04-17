local Parser = require("igit.libp.argparse.Parser")

describe("add_argument", function()
	describe("positional", function()
		it("Defaults to required", function()
			local parser = Parser()
			parser:add_argument("a")
			local res = parser:parse("")
			assert.are.same(nil, res)
		end)
		describe("type", function()
			it("Defaults to string type", function()
				local parser = Parser()
				parser:add_argument("a")
				local res = parser:parse("1")
				assert.are.same({ a = "1" }, res)
			end)

			it("Converts types", function()
				local parser = Parser()
				parser:add_argument("a", { type = "number" })
				local res = parser:parse("1")
				assert.are.same({ a = 1 }, res)
			end)
		end)

		describe("nargs", function()
			it("Defaults to 1", function()
				local parser = Parser()
				parser:add_argument("a")
				local res = parser:parse("1 2")
				assert.are.same(nil, res)
			end)

			it("Respects nargs", function()
				local parser = Parser()
				parser:add_argument("a", { nargs = 2 })
				local res = parser:parse("1 2")
				assert.are.same({ a = { "1", "2" } }, res)
			end)
		end)
	end)

	describe("flags", function()
		it("Defaults to not required", function()
			local parser = Parser()
			parser:add_argument("a")
			parser:add_argument("--flag")
			local res = parser:parse("1")
			assert.are.same({ a = "1" }, res)

			res = parser:parse("--flag f 1")
			assert.are.same({ a = "1", flag = "f" }, res)
		end)

		it("Respect required", function()
			local parser = Parser()
			parser:add_argument("a")
			parser:add_argument("--flag", { required = true })
			local res = parser:parse("1")
			assert.are.same(nil, res)

			res = parser:parse("--flag f 1")
			assert.are.same({ a = "1", flag = "f" }, res)
		end)

		it("Respect nargs", function()
			local parser = Parser()
			parser:add_argument("a", { type = "number" })
			parser:add_argument("--flag", { nargs = 2 })
			local res = parser:parse("--flag f1 f2 1")
			assert.are.same({ a = 1, flag = { "f1", "f2" } }, res)
		end)
	end)
end)

describe("add_subparser", function()
	it("Takes a parser instance", function()
		local parser = Parser("prog")
		local sub_parser = Parser("sub")
		parser:add_subparser(sub_parser)
		assert.are.same({ { "prog", {} }, { "sub", {} } }, parser:parse("sub"))
	end)

	it("Takes multiple sub_parsers", function()
		local parser = Parser("prog")
		parser:add_subparser("sub1")
		parser:add_subparser("sub2")
		assert.are.same({ { "prog", {} }, { "sub1", {} } }, parser:parse("sub1"))
		assert.are.same({ { "prog", {} }, { "sub2", {} } }, parser:parse("sub2"))
	end)

	it("Takes recursive sub_parsers", function()
		local parser = Parser("prog")
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_subparser("subsub")
		assert.are.same({ { "prog", {} }, { "sub", {} }, { "subsub", {} } }, parser:parse("sub subsub"))
	end)

	it("Respects global options", function()
		local parser = Parser()
		parser:add_argument("a", { type = "number" })
		parser:add_argument("--flag", { nargs = 2 })
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_argument("sub_a", { type = "number" })
		sub_parser:add_argument("--sub_flag", { nargs = 2 })
		local res = parser:parse("--flag f1 f2 1 sub --sub_flag subf1 subf2 2")
		assert.are.same({
			{ "", { a = 1, flag = { "f1", "f2" } } },
			{ "sub", { sub_a = 2, sub_flag = { "subf1", "subf2" } } },
		}, res)
	end)

	it("Returns hierarchical result", function()
		local parser = Parser("prog")
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_subparser("subsub")
		assert.are.same({ { "prog", {} }, { "sub", {} }, { "subsub", {} } }, parser:parse("sub subsub", true))
	end)
end)

describe("get_completion_list", function()
	local parser = nil
	before_each(function()
		parser = Parser()
		parser:add_argument("a", { type = "number" })
		parser:add_argument("--flag", { nargs = 2 })
		parser:add_subparser("sub2")
		local sub_parser = parser:add_subparser("sub")
		sub_parser:add_argument("sub_a", { type = "number" })
		sub_parser:add_argument("--sub_flag", { nargs = 2 })
	end)

	it("Returns top flag and subcommands", function()
		assert.are.same({
			"--flag",
			"sub",
			"sub2",
		}, parser:get_completion_list(""))
	end)

	it("Returns things statrs with hint", function()
		assert.are.same({
			"--flag",
		}, parser:get_completion_list("", "-"))
		assert.are.same({
			"--flag",
		}, parser:get_completion_list("", "--"))
	end)

	it("Returns sub-flags", function()
		assert.are.same({ "--sub_flag" }, parser:get_completion_list("sub"))
		assert.are.same({}, parser:get_completion_list("sub2"))
	end)

	it("Returns sub-flags with hints", function()
		assert.are.same({ "--sub_flag" }, parser:get_completion_list("sub", "-"))
	end)
end)
