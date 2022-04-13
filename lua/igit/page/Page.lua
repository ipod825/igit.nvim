local M = require("igit.libp.datatype.Class"):EXTEND()
local path = require("igit.libp.path")
local Set = require("igit.libp.datatype.Set")
local job = require("igit.libp.job")
local log = require("igit.log")
local ui = require("igit.libp.ui")

function M:open_or_new_buffer(key, opts)
	if opts.git_root == nil or opts.git_root == "" then
		vim.notify("No git project found!")
		return
	end

	if type(key) == "table" then
		key = table.concat(key, "")
	end

	vim.validate({
		key = { key, "string" },
		git_root = { opts.git_root, "string" },
		type = { opts.type, "string" },
	})

	self.buffer_index = self.buffer_index or Set()
	local index = Set.size(self.buffer_index)
	Set.add(self.buffer_index, key, (index == 0) and "" or tostring(index))

	opts = vim.tbl_deep_extend("force", {
		open_cmd = "tab drop",
		filename = ("igit://%s-%s%s"):format(path.basename(opts.git_root), opts.type, self.buffer_index[key]),
		b = { git_root = opts.git_root },
		bo = vim.tbl_extend("keep", opts.bo or {}, {
			filetype = "igit",
			bufhidden = "hide",
			buftype = "nofile",
			modifiable = false,
		}),
	}, opts)

	local buffer = ui.Buffer.open_or_new(opts)
	vim.cmd("lcd " .. opts.git_root)
	return buffer
end

function M:current_buf()
	return ui.Buffer.get_current_buffer()
end

function M:runasync_and_reload(cmd)
	local current_buf = self:current_buf()
	job.start(cmd)
	current_buf:reload()
end

function M:runasync_all_and_reload(cmds)
	local current_buf = self:current_buf()
	job.start_all(cmds)
	current_buf:reload()
end

return M
