local M = require("libp.datatype.Class"):EXTEND()
local path = require("libp.path")
local Set = require("libp.datatype.Set")
local Job = require("libp.Job")
local log = require("igit.log")
local ui = require("libp.ui")

function M:open_or_new_buffer(key, opts, buf_opts)
	if opts.git_root == nil or opts.git_root == "" then
		vim.notify("No git project found!")
		return
	end

	if type(key) == "table" then
		key = table.concat(key, "")
	end

	vim.validate({
		key = { key, "s" },
		git_root = { opts.git_root, "s" },
		type = { opts.type, "s" },
	})

	self.buffer_index = self.buffer_index or Set()
	local index = Set.size(self.buffer_index)
	Set.add(self.buffer_index, key, (index == 0) and "" or tostring(index))

	buf_opts = vim.tbl_deep_extend("force", {
		open_cmd = "tab drop",
		filename = ("igit://%s-%s%s"):format(path.basename(opts.git_root), opts.type, self.buffer_index[key]),
		b = { git_root = opts.git_root },
		bo = {
			filetype = "igit",
			bufhidden = "hide",
		},
	}, buf_opts)

	local buffer
	if #buf_opts.open_cmd == 0 then
		buffer = ui.Buffer.get_or_new(buf_opts)
		local grid = ui.Grid()
		grid:add_row({ focusable = true }):fill_window(ui.Window(buffer, { focus_on_open = true }))
		grid:show()
	else
		buffer = ui.Buffer.open_or_new(buf_opts)
	end

	vim.cmd("lcd " .. opts.git_root)
	return buffer
end

function M:current_buf()
	return ui.Buffer.get_current_buffer()
end

function M:runasync_and_reload(cmd)
	local current_buf = self:current_buf()
	Job({ cmds = cmd }):start()
	current_buf:reload()
end

function M:runasync_all_and_reload(cmds)
	local current_buf = self:current_buf()
	Job.start_all(cmds)
	current_buf:reload()
end

return M
