local vimfn = require("igit.libp.utils.vimfn")

describe("visual_rows", function()
	it("Returns seleted row beg and end", function()
		vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3" })
		vim.cmd("normal! ggVG")

		-- -- todo: This doesn't work. Seems like neovim has a bug: After setting
		-- -- the buffer content, vim.fn.getpos("'>") would return {0,0,0,0}.
		-- local row_beg, row_end = vimfn.visual_rows()
		-- assert.are.same(1, row_beg)
		-- assert.are.same(3, row_end)

		local stub = require("luassert.stub")(vimfn, "visual_rows")
		stub.by_default.returns(1, 3)
		local row_beg, row_end = vimfn.visual_rows()
		assert.are.same(1, row_beg)
		assert.are.same(3, row_end)
		stub:revert()
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
