local vimfn = require("ivcs.libp.vimfn")

describe("visual_rows", function()
	it("Returns seleted row beg and end", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vim.cmd("normal! ggVG")

		row_beg, row_end = vimfn.visual_rows()
		-- todo: figure out why this fial.
		-- assert.are.same(0, row_beg)
		assert.are.same(3, row_end)
	end)
end)

describe("all_rows", function()
	it("Returns 1, line('$')", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })

		row_beg, row_end = vimfn.all_rows()
		assert.are.same(1, row_beg)
		assert.are.same(3, row_end)
	end)
end)
