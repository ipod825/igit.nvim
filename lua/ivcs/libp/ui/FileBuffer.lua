local M = require("ivcs.libp.datatype.Class"):EXTEND()
local a = require("plenary.async")
local job = require("ivcs.libp.job")

function M:init(filename)
	vim.validate({ filename = { filename, "string" } })

	if vim.fn.bufexists(filename) > 0 then
		self.id = vim.fn.bufadd(filename)
		return self.id
	end

	self.id = vim.api.nvim_create_buf(true, false)

	vim.api.nvim_buf_set_option(self.id, "modifiable", false)
	vim.api.nvim_buf_set_option(self.id, "undolevels", -1)
	vim.api.nvim_buf_set_option(self.id, "undofile", false)

	job.start("cat " .. filename, {
		on_stdout = function(lines)
			if not vim.api.nvim_buf_is_valid(self.id) then
				return true
			end

			vim.api.nvim_buf_set_option(self.id, "modifiable", true)
			vim.api.nvim_buf_set_lines(self.id, -2, -1, false, lines)
			vim.api.nvim_buf_set_option(self.id, "modifiable", false)
		end,
	})
	vim.api.nvim_buf_set_name(self.id, filename)
	vim.api.nvim_buf_set_option(self.id, "undolevels", vim.api.nvim_get_option("undolevels"))
	vim.api.nvim_buf_set_option(self.id, "modified", false)
	vim.api.nvim_buf_set_option(self.id, "modifiable", true)

	-- nvim_buf_set_name only associates the buffer with the filename. On
	-- first write, E13 (file exists) happens. The workaround here just
	-- force wrintg the file (or do it on next bufer enter). This can be
	-- improved when there's an API for writing a buffer to a file that
	-- takes a buf id.
	local associate_file = function()
		vim.api.nvim_command("silent! w!")
		vim.api.nvim_buf_set_option(self.id, "undofile", vim.o.undofile)
	end
	if vim.api.nvim_get_current_buf() == self.id then
		associate_file()
	else
		vim.api.nvim_create_autocmd("BufEnter", {
			buffer = self.id,
			once = true,
			callback = associate_file,
		})
	end
end

return M
