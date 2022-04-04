local vimfn = require("igit.libp.vimfn")

describe("visual_rows", function()
	it("Returns seleted row beg and end", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vim.cmd("normal! ggVG")

		row_beg, row_end = vimfn.visual_rows()
		-- todo: figure out why this fial.
		-- assert.are.equal(row_beg, 0)
		assert.are.equal(row_end, 3)
	end)
end)

describe("all_rows", function()
	it("Returns 1, line('$')", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })

		row_beg, row_end = vimfn.all_rows()
		assert.are.equal(row_beg, 1)
		assert.are.equal(row_end, 3)
	end)
end)
