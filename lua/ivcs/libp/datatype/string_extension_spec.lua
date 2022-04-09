require("ivcs.libp.datatype.string_extension")

describe("find_str", function()
	it("Returns nil if no match", function()
		local a = "abc def ghi"
		assert.is_nil(a:find_str("defg"), nil)
	end)

	it("Finds matched string", function()
		local a = "abc def ghi"
		assert.are.equal(a:find_str("(def)"), "def")
	end)
end)

describe("split white space", function()
	it("Defaults to use space as delimiter", function()
		local a = "abc def ghi"
		assert.are.same(a:split(), { "abc", "def", "ghi" })
	end)

	it("Removes leading white space", function()
		local a = "     abc def ghi"
		assert.are.same(a:split(" "), { "abc", "def", "ghi" })
	end)

	it("Removes multiple white space", function()
		local a = "     abc        def ghi"
		assert.are.same(a:split(" "), { "abc", "def", "ghi" })
	end)
end)

describe("split non-white space", function()
	it("Does not remove leading/tailing delimiter", function()
		local a = "\nabc\ndef\nghi\n"
		assert.are.same(a:split("\n"), { "", "abc", "def", "ghi", "" })
	end)

	it("Does not remove multiple delimiter", function()
		local a = "abc\n\ndef\nghi"
		assert.are.same(a:split("\n"), { "abc", "", "def", "ghi" })
	end)
end)

describe("split_trim", function()
	it("Defaults to use space as delimiter", function()
		local a = "abc def ghi"
		assert.are.same(a:split_trim(), { "abc", "def", "ghi" })
	end)

	it("Returns array with splited string", function()
		local a = "abc def ghi"
		assert.are.same(a:split_trim(" "), { "abc", "def", "ghi" })
	end)

	it("Trims each element", function()
		local a = "abc, def, ghi"
		assert.are.same(a:split_trim(","), { "abc", "def", "ghi" })
	end)
end)

describe("trim", function()
	it("Trims spaces", function()
		local a = " def "
		assert.are.same(a:trim(), "def")
	end)
end)

describe("startswith", function()
	it("Returns true if the string starts with pattern", function()
		local a = "abc def"
		assert.is_truthy(a:startswith("abc"))
		assert.is_falsy(a:startswith("def"))
	end)
end)

describe("endsswith", function()
	it("Returns true if the string endss with pattern", function()
		local a = "abc def"
		assert.is_truthy(a:endswith("def"))
		assert.is_falsy(a:endswith("abc"))
	end)
end)

describe("unquote", function()
	it("Returns empty string for empty string", function()
		assert.are.equal((""):unquote(), "")
	end)
	it("Unquotes single quotation", function()
		assert.are.equal(("'a'"):unquote(), "a")
	end)
	it("Unquotes double quotation", function()
		assert.are.equal(('"a"'):unquote(), "a")
	end)
end)
