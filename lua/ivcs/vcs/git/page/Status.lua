local M = require("ivcs.vcs.git.page.Page"):EXTEND()
local git = require("ivcs.vcs.git.git")
local job = require("ivcs.libp.job")
local global = require("ivcs.global")
local vimfn = require("ivcs.libp.vimfn")
local Iterator = require("ivcs.libp.datatype.Iterator")
local ui = require("ivcs.libp.ui")
local path = require("ivcs.libp.path")
local a = require("plenary.async")
local log = require("ivcs.log")

function M:init(options)
	self.options = vim.tbl_deep_extend("force", {
		mapping = {
			n = {
				["H"] = self:BIND(self.stage_change),
				["L"] = self:BIND(self.unstage_change),
				["X"] = self:BIND(self.discard_change),
				["C"] = self:BIND(self.clean_files),
				["cc"] = self:BIND(self.commit),
				["ca"] = self:BIND(self.commit, { amend = true }),
				["cA"] = self:BIND(self.commit, { amend = true, backup_branch = true }),
				["dd"] = self:BIND(self.side_diff),
				["ds"] = self:BIND(self.side_stage_diff),
				["<cr>"] = self:BIND(self.open_file),
				["t"] = self:BIND(self.open_file, "tab drop"),
			},
			v = {
				["X"] = self:BIND(self.discard_change),
				["H"] = self:BIND(self.stage_change),
				["L"] = self:BIND(self.unstage_change),
			},
		},
		args = { "-s" },
	}, options or {})
end

function M:open_file(open_cmd)
	open_cmd = open_cmd or "edit"
	vim.cmd(("%s %s"):format(open_cmd, self:parse_line().abs_path))
end

function M:commit_submit(git_dir, opts)
	opts = opts or {}
	vim.validate({
		amend = { opts.amend, "boolean", true },
		backup_branch = { opts.backup_branch, "boolean", true },
	})
	if global.pending_commit[git_dir] == nil then
		return
	end
	global.pending_commit[git_dir] = nil

	local lines = vim.tbl_filter(function(e)
		return e:sub(1, 1) ~= "#"
	end, vim.fn.readfile(git.commit_message_file_path(git_dir)))
	local gita = git.with_default_args({ git_dir = git_dir })
	if opts.backup_branch then
		local base_branch = job.check_output(gita.branch("--show-current"))
		local backup_branch = ("%s_original_created_by_ivcs"):format(base_branch)
		job.start(gita.branch(("%s %s"):format(backup_branch, base_branch)))
	end
	job.start(gita.commit(('%s -m "%s"'):format(opts.amend and "--amend" or "", table.concat(lines, "\n"))))
end

function M:commit(opts)
	opts = opts or {}
	local git_dir = git.find_root()
	local amend = opts.amend and "--amend" or ""
	local prepare_commit_file_cmd = "GIT_EDITOR=false git commit " .. amend
	job.start(prepare_commit_file_cmd, { silent = true })
	local commit_message_file_path = git.commit_message_file_path(git_dir)
	vim.cmd("edit " .. commit_message_file_path)
	vim.bo.bufhidden = "wipe"
	global.pending_commit = global.pending_commit or {}
	vim.api.nvim_create_autocmd("BufWritePre", {
		buffer = 0,
		once = true,
		callback = function()
			global.pending_commit[git_dir] = true
		end,
	})
	vim.api.nvim_create_autocmd("Bufunload", {
		buffer = 0,
		once = true,
		callback = a.void(function()
			self:commit_submit(git_dir, opts)
		end),
	})
end

function M:change_action(action)
	local status = git.status_porcelain()
	local filepaths = Iterator.range(vimfn.visual_rows())
		:map(function(e)
			local filepath = self:parse_line(e).filepath
			return status[filepath] and filepath or ""
		end)
		:collect()
	self:runasync_and_reload(action(filepaths))
	return #filepaths == 1
end

function M:side_stage_diff()
	local cline_info = self:parse_line()

	local grid = ui.Grid()
	local stage_buf = ui.Buffer({
		filename = ("ivcs://STAGE:%s"):format(cline_info.filepath),
		bo = { modifiable = true, undolevels = vim.o.undolevels },
		content = function()
			return git.show(":%s"):format(cline_info.filepath)
		end,
	})

	local staged_lines = nil
	vim.api.nvim_buf_attach(stage_buf.id, false, {
		on_lines = function(...)
			if not stage_buf.is_reloading then
				staged_lines = vim.api.nvim_buf_get_lines(stage_buf.id, 0, -1, true)
			end
		end,
		on_detach = vim.schedule_wrap(a.void(function()
			if staged_lines == nil then
				return
			end
			local _, fd = a.uv.fs_open(cline_info.abs_path, "w", 448)
			local err, stat = a.uv.fs_fstat(fd)
			if err then
				log.want(err)
				vim.notify(err)
				return
			end
			local _, ori_content = a.uv.fs_read(fd, stat.size, 0)
			log.warn(table.concat(staged_lines, "\n"))
			a.uv.fs_write(fd, table.concat(staged_lines, "\n"), 0)
			job.start(git.add(cline_info.filepath))
			a.uv.fs_write(fd, ori_content, 0)
			a.uv.fs_close(fd)
		end)),
	})

	local worktree_buf = ui.FileBuffer(cline_info.abs_path)
	vim.filetype.match(cline_info.abs_path, stage_buf.id)
	vim.filetype.match(cline_info.abs_path, worktree_buf.id)

	grid:add_row({ height = 1 }):fill_window(ui.Window(ui.Buffer({ content = { cline_info.filepath } })))
	grid:add_row({ height = 1 }):vfill_windows({
		ui.Window(ui.Buffer({ content = { "                 STAGE" } })),
		ui.Window(ui.Buffer({ content = { "           Worktree" } })),
	})
	grid:add_row({ focusable = true, height = -1 }):vfill_windows({
		ui.DiffWindow(stage_buf),
		ui.DiffWindow(worktree_buf, { focus_on_open = true }),
	}, true)
	grid:show()
end

function M:side_diff()
	local cline_info = self:parse_line()

	local grid = ui.Grid()
	local index_buf = ui.Buffer({
		filename = ("ivcs://HEAD:%s"):format(cline_info.filepath),
		content = function()
			return git.show(":%s"):format(cline_info.filepath)
		end,
	})
	local worktree_buf = ui.FileBuffer(cline_info.abs_path)
	vim.filetype.match(cline_info.abs_path, index_buf.id)
	vim.filetype.match(cline_info.abs_path, worktree_buf.id)

	grid:add_row({ height = 1 }):fill_window(ui.Window(ui.Buffer({ content = { cline_info.filepath } })))
	grid:add_row({ height = 1 }):vfill_windows({
		ui.Window(ui.Buffer({ content = { "                 HEAD" } })),
		ui.Window(ui.Buffer({ content = { "           Worktree" } })),
	})
	grid:add_row({ focusable = true, height = -1 }):vfill_windows({
		ui.DiffWindow(index_buf),
		ui.DiffWindow(worktree_buf, { focus_on_open = true }),
	}, true)
	grid:show()
end

function M:clean_files()
	self:change_action(function(filepath)
		return git.clean("-ffd", filepath)
	end)
end

function M:discard_change()
	self:change_action(function(filepath)
		return git.restore(filepath)
	end)
end

function M:stage_change()
	if self:change_action(function(filepath)
		return git.add(filepath)
	end) then
		vim.cmd("normal! j")
	end
end

function M:unstage_change()
	if self:change_action(function(filepath)
		return git.restore("--staged", filepath)
	end) then
		vim.cmd("normal! j")
	end
end

function M:parse_line(line_nr)
	line_nr = line_nr or "."
	local res = {}
	local line = vim.fn.getline(line_nr)
	res.filepath = line:find_str("[^%s]+%s+([^%s]+)$")
	res.abs_path = path.path_join(git.find_root(), res.filepath)
	return res
end

function M:open(args)
	args = args or self.options.args
	self:open_or_new_buffer(args, {
		git_root = git.find_root(),
		type = "status",
		mappings = self.options.mapping,
		buf_enter_reload = true,
		content = function()
			return git.status(args)
		end,
	})
end

return M
