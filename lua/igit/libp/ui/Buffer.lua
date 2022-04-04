local M = require("igit.libp.datatype.Class"):EXTEND()
local global = require("igit.libp.global")("libp")
local functional = require("igit.libp.functional")
local a = require("plenary.async")
local job = require("igit.libp.job")
local log = require("igit.log")

function M.get_current_buffer()
	return global.buffers[vim.api.nvim_get_current_buf()]
end

function M.open_or_new(opts)
	vim.validate({
		open_cmd = { opts.open_cmd, "string" },
		filename = { opts.filename, "string" },
	})

	vim.cmd(("%s %s"):format(opts.open_cmd, opts.filename))
	global.buffers = global.buffers or {}
	opts.id = vim.api.nvim_get_current_buf()
	if global.buffers[opts.id] == nil then
		global.buffers[opts.id] = M(opts)
	elseif not global.buffers[opts.id].buf_enter_reload then
		global.buffers[opts.id]:reload()
	end
	return global.buffers[opts.id]
end

function M:init(opts)
	vim.validate({
		id = { opts.id, "number", true },
		content = { opts.content, { "function", "table" } },
		buf_enter_reload = { opts.buf_enter_reload, "boolean", true },
		mappings = { opts.mappings, "table", true },
		b = { opts.b, "table", true },
		bo = { opts.bo, "table", true },
	})

	if opts.id then
		assert(global.buffers[opts.id] == nil, "Each vim buffer can only maps to one Buffer instance")
	end

	self.id = opts.id or vim.api.nvim_create_buf(false, true)
	global.buffers = global.buffers or {}
	global.buffers[self.id] = self

	self.content = opts.content or functional.nop
	self.mappings = opts.mappings
	self:mapfn(opts.mappings)

	-- For client to store arbitrary lua object.
	local ctx = {}
	self.ctx = setmetatable({}, { __index = ctx, __newindex = ctx })

	self.namespace = vim.api.nvim_create_namespace("")

	for k, v in pairs(opts.b or {}) do
		vim.api.nvim_buf_set_var(self.id, k, v)
	end

	local bo = vim.tbl_extend("force", {
		modifiable = false,
		bufhidden = "wipe",
		buftype = "nofile",
		undolevels = -1,
		swapfile = false,
	}, opts.bo or {})
	for k, v in pairs(bo) do
		vim.api.nvim_buf_set_option(self.id, k, v)
	end
	self.undolevels = bo.undolevels
	self.filetype = bo.filetype

	-- free memory on wipe
	vim.api.nvim_create_autocmd("BufDelete", {
		buffer = self.id,
		once = true,
		callback = function()
			global.buffers[self.id] = nil
		end,
	})

	-- reload on :edit
	vim.api.nvim_create_autocmd("BufReadCmd", {
		buffer = self.id,
		callback = a.void(function()
			self:reload()
		end),
	})

	-- reload on BufEnter
	if opts.buf_enter_reload then
		vim.api.nvim_create_autocmd("BufEnter", {
			buffer = self.id,
			callback = a.void(function()
				self:reload()
			end),
		})
	end

	self:reload()
end

function M:mapfn(mappings)
	if not mappings then
		return
	end
	self.mapping_handles = self.mapping_handles or {}
	for mode, mode_mappings in pairs(mappings) do
		vim.validate({
			mode = { mode, "string" },
			mode_mappings = { mode_mappings, "table" },
		})
		self.mapping_handles[mode] = self.mapping_handles[mode] or {}
		for key, fn in pairs(mode_mappings) do
			self:add_key_map(mode, key, fn)
		end
	end
end

function M:add_key_map(mode, key, fn)
	vim.validate({
		mode = { mode, "string" },
		key = { key, "string" },
		fn = { fn, { "function", "table" } },
	})

	local modify_buffer = true
	if type(fn) == "table" then
		modify_buffer = fn.modify_buffer or true
		fn = fn.callback
	end

	local prefix = (mode == "v") and ":<c-u>" or "<cmd>"
	self.mapping_handles[mode] = self.mapping_handles[mode] or {}
	self.mapping_handles[mode][key] = function()
		if self.is_reloading and modify_buffer then
			-- Cancel reload since we will reload after calling fn.
			self.cancel_reload = true
		end
		fn()
	end
	vim.api.nvim_buf_set_keymap(
		self.id,
		mode,
		key,
		('%slua require("igit.libp.ui.Buffer").execut_mapping("%s", "%s")<cr>'):format(
			prefix,
			mode,
			key:gsub("^<", "<lt>")
		),
		{}
	)
end

function M.execut_mapping(mode, key)
	local b = global.buffers[vim.api.nvim_get_current_buf()]
	key = key:gsub("<lt>", "^<")
	a.void(function()
		b.mapping_handles[mode][key]()
	end)()
end

function M:mark(data, max_num_data)
	self.ctx.mark = self.ctx.mark or {}
	if #self.ctx.mark == max_num_data then
		self.ctx.mark = {}
	end
	local index = (#self.ctx.mark % max_num_data) + 1
	self.ctx.mark[index] = vim.tbl_extend("error", data, { linenr = vim.fn.line(".") - 1 })

	vim.api.nvim_buf_clear_namespace(self.id, self.namespace, 1, -1)
	for i, d in ipairs(self.ctx.mark) do
		local hi_group
		if i == 1 then
			hi_group = "RedrawDebugRecompose"
		elseif i == 2 then
			hi_group = "DiffAdd"
		end
		vim.api.nvim_buf_add_highlight(self.id, self.namespace, hi_group, d.linenr, 1, -1)
	end
end

function M:save_edit()
	self.ctx.edit.update(self.ctx.edit.ori_items, self.ctx.edit.get_items())
	self.ctx.edit = nil
	vim.bo.buftype = "nofile"
	vim.bo.modifiable = false
	vim.bo.undolevels = self.undolevels
	self:mapfn(self.mappings)
	self:reload()
end

function M:edit(opts)
	vim.validate({
		get_items = { opts.get_items, "function" },
		update = { opts.update, "function" },
	})
	self.ctx.edit = vim.tbl_extend("error", opts, { ori_items = opts.get_items() })
	vim.bo.buftype = "acwrite"
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = self.id,
		once = true,
		callback = a.void(function()
			global.buffers[self.id]:save_edit()
		end),
	})
	self:unmapfn(self.mappings)
	vim.bo.undolevels = -1
	vim.bo.modifiable = true
	vim.cmd("substitute/\\e\\[[0-9;]*m//g")
	vim.bo.undolevels = (self.undolevels > 0) and self.undolevels or vim.api.nvim_get_option("undolevels")
end

function M:unmapfn(mappings)
	for mode, mode_mappings in pairs(mappings) do
		vim.validate({
			mode = { mode, "string" },
			mode_mappings = { mode_mappings, "table" },
		})
		for key, _ in pairs(mode_mappings) do
			vim.api.nvim_buf_del_keymap(self.id, mode, key)
		end
	end
end

function M:clear()
	vim.api.nvim_buf_set_option(self.id, "modifiable", true)
	vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
	vim.api.nvim_buf_set_option(self.id, "modifiable", false)
end

function M:append(lines)
	vim.api.nvim_buf_set_option(self.id, "modifiable", true)
	-- Note that we assume the last element in lines is always '' which will be
	-- overwriten by the next append call as the start index is -2. The reason
	-- start index is not -1 is for consistency between calls of append. On
	-- empty buffer, the first line is always non-empty, insertion starting from
	-- -1 will insert from the second line.
	vim.api.nvim_buf_set_lines(self.id, -2, -1, false, lines)
	vim.api.nvim_buf_set_option(self.id, "modifiable", false)
end

function M:save_view()
	if self.id == vim.api.nvim_get_current_buf() then
		self.saved_view = vim.fn.winsaveview()
	end
end

function M:restore_view()
	if self.saved_view and self.id == vim.api.nvim_get_current_buf() then
		vim.fn.winrestview(self.saved_view)
		self.saved_view = nil
	end
end

function M:register_reload_notification()
	-- This functoin is mainly for testing purpose. When the reload function is
	-- not invoked by the main testing coroutine (a.void) but by a (autocmd)
	-- callback, the main testing coroutine won't block until reload finishes as
	-- reload is invoked by another coroutine. This function returns a mutex so
	-- that the other coroutine can notify the main testing coroutine when it
	-- completes the reload function.
	self.reload_done = a.control.Condvar.new()
	return self.reload_done
end

function M:reload()
	if self.filetype then
		vim.api.nvim_buf_set_option(self.id, "filetype", self.filetype)
	end
	if type(self.content) == "table" then
		vim.api.nvim_buf_set_option(self.id, "modifiable", true)
		vim.api.nvim_buf_set_lines(self.id, 0, -1, false, self.content)
		vim.api.nvim_buf_set_option(self.id, "modifiable", false)
		return
	end

	if self.is_reloading then
		return
	end

	self.is_reloading = true
	-- Clear the marks so that we don't hit into invisible marks.
	self.ctx.mark = nil
	self.cancel_reload = false
	self:save_view()
	self:clear()

	local count = 1
	local w = vim.api.nvim_get_current_win()
	local ori_st = vim.o.statusline
	job.start(self.content(), {
		on_stdout = function(lines)
			if not vim.api.nvim_buf_is_valid(self.id) or self.cancel_reload then
				return true
			end

			self:append(lines)
			-- We only restore view once (note that restore_view destroys
			-- the saved view). This is because that for content that can be
			-- drawn in one shot, reload should finish before any new user
			-- interaction. Restoring the view thus compensate the cursor
			-- move (due to clear). But for content that needs to be drawn
			-- in multiple run, restoring the cursor after every append
			-- just makes user can't do anything.
			self:restore_view()

			if w == vim.api.nvim_get_current_win() then
				vim.wo.statusline = " Loading " .. ("."):rep(count)
				count = count % 6 + 1
			end
		end,
	})

	self.is_reloading = false
	if vim.api.nvim_win_is_valid(w) then
		vim.api.nvim_win_set_option(w, "statusline", ori_st)
	end

	if self.reload_done then
		self.reload_done:notify_one()
	end
end

return M
