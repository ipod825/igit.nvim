local term_utils = require("igit.libp.term_utils")

describe("remove_ansi_escape", function()
	it("Removes ansi escape", function()
		local c27 = function(s)
			s = s or ""
			return ("%s[%sm"):format(string.char(27), s)
		end
		local text = "TEXT"

		assert.are.same(text, term_utils.remove_ansi_escape(c27(30) .. text .. c27()))
		assert.are.same(text, term_utils.remove_ansi_escape(c27(30) .. c27(4) .. text .. c27()))
	end)
end)

describe("tokenize_command", function()
	it("Removes beginning/trailing space", function()
		assert.are.same({ "abc", "def" }, term_utils.tokenize_command("  abc def  "))
	end)

	it("Removes space between equal sign", function()
		assert.are.same({ "abc=def", "hij=klm" }, term_utils.tokenize_command("abc =  def hij = klm"))
		assert.are.same({ [[abc="def"]], [[hij='klm']] }, term_utils.tokenize_command([[  abc =  "def" hij = 'klm'  ]]))
		assert.are.same({ [[abc="def"]], [[hij='klm']] }, term_utils.tokenize_command([[abc =  "def" hij = 'klm']]))
	end)

	it("Works with escaped quote", function()
		assert.are.same(
			{ [[abc="\"def\""]], [[hij="'klm'"]] },
			term_utils.tokenize_command([[abc="\"def\"" hij="'klm'"]])
		)
		assert.are.same(
			{ [[abc="\"def\""]], [[hij="'klm'"]] },
			term_utils.tokenize_command([[abc =  "\"def\"" hij = "'klm'"]])
		)
	end)

	it("Returns nil on missing quote", function()
		assert.are.same({ [[abc="'def"]] }, term_utils.tokenize_command([[abc="'def"]]))
		assert.are.same({ [[abc='"def']] }, term_utils.tokenize_command([[abc='"def']]))

		assert.is_nil(term_utils.tokenize_command([[abc="def]]))
		assert.is_nil(term_utils.tokenize_command([[abc='def]]))
		assert.is_nil(term_utils.tokenize_command([[abc="\"def\" hij="'klm'"]]))
	end)
end)
