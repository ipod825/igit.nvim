local term_utils = require("igit.libp.utils.term")

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
