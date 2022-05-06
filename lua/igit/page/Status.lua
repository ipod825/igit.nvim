local M = require("igit.page.Page"):EXTEND()
local git = require("igit.git")
local Job = require("libp.Job")
local global = require("igit.global")
local vimfn = require("libp.utils.vimfn")
local ui = require("libp.ui")
local path = require("libp.path")
local a = require("plenary.async")
local log = require("igit.log")

function M:setup(options)
	vim.validate({ options = { options, "t" } })

	self.options = vim.tbl_deep_extend("force", {
		mappings = {
			n = {
				["H"] = self:BIND(self.stage_change),
				["L"] = self:BIND(self.unstage_change),
				["X"] = self:BIND(self.discard_change),
				["C"] = self:BIND(self.clean_files),
				["cc"] = self:BIND(self.commit),
				["ca"] = self:BIND(self.commit, { amend = true }),
				["cA"] = self:BIND(self.commit, { amend = true, backup_branch = true }),
				["dh"] = self:BIND(self.diff_index),
				["dd"] = self:BIND(self.diff_cached),
				["<cr>"] = self:BIND(self.open_file),
				["t"] = self:BIND(self.open_file, "tab drop"),
			},
			v = {
				["H"] = self:BIND(self.stage_change),
				["L"] = self:BIND(self.unstage_change),
				["X"] = self:BIND(self.discard_change),
				["C"] = self:BIND(self.clean_files),
			},
		},
	}, options)
	return self
end

function M:open_file(open_cmd)
	open_cmd = open_cmd or "edit"
	vim.cmd(("%s %s"):format(open_cmd, self:parse_line().abs_path))
end

function M:commit_submit(git_dir, opts)
	opts = opts or {}
	vim.validate({

		amend = { opts.amend, "b", true },
		backup_branch = { opts.backup_branch, "b", true },
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
		local base_branch = Job({ cmds = gita.branch("--show-current") }):stdoutputstr()
		local backup_branch = ("%s_original_created_by_igit"):format(base_branch)
		Job({ cmds = gita.branch(backup_branch, base_branch) }):start()
	end
	Job({ cmds = gita.commit({ opts.amend and "--amend", "-m", table.concat(lines, "\n") }) }):start()
end

function M:commit(opts)
	opts = opts or {}
	local git_dir = git.find_root()
	local amend = opts.amend and "--amend"
	Job({ cmds = git.commit(amend), stderr_dump_level = Job.StderrDumpLevel.SILENT, env = { GIT_EDITOR = "false" } }):start()
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
	local current_buf = self:current_buf()
	local status = git.status_porcelain()
	local filepaths = {}
	local file_count = 0
	local b, e = vimfn.visual_rows()

	-- Run the command once for each different status as some might fail (for
	-- e.g., we can't unstage untracked files). If we run a single command. No
	-- progress is made and the user is forced to do it in multi-steps.
	for i = b, e do
		local filepath = self:parse_line(i).filepath
		local s = status[filepath].state
		if s then
			filepaths[s] = filepaths[s] or {}
			table.insert(filepaths[s], filepath)
			file_count = file_count + 1
		end
	end

	-- Note that using start_all here might lead to git index lock issue. Hence
	-- we run the commands sequentially here.
	for _, files in pairs(filepaths) do
		Job({ cmds = action(files) }):start()
	end
	current_buf:reload()
	return file_count == 1
end

function M:diff_cached()
	local cline_info = self:parse_line()

	local grid = ui.Grid()
	local not_indexed = git.status_porcelain(cline_info.filepath)[cline_info.filepath].index == "?"
	local stage_buf = ui.Buffer({
		filename = ("igit://STAGE:%s"):format(cline_info.filepath),
		bo = { modifiable = true, undolevels = vim.go.undolevels },
		content = not_indexed and {} or function()
			return git.show((":%s"):format(cline_info.filepath))
		end,
	})

	local delay_reload = self:current_buf():delay_reload()
	local staged_lines = nil
	vim.api.nvim_buf_attach(stage_buf.id, false, {
		on_lines = function()
			if not stage_buf.is_reloading then
				staged_lines = vim.api.nvim_buf_get_lines(stage_buf.id, 0, -1, true)
			end
		end,
		on_detach = a.void(function()
			if staged_lines == nil then
				return
			end
			local _, fd = a.uv.fs_open(cline_info.abs_path, "r", 448)
			local err, stat = a.uv.fs_fstat(fd)
			if err then
				log.want(err)
				vim.notify(err)
				return
			end
			local _, ori_content = a.uv.fs_read(fd, stat.size)
			a.uv.fs_close(fd)

			_, fd = a.uv.fs_open(cline_info.abs_path, "w", 448)
			-- File needs to be ended with a new line.
			a.uv.fs_write(fd, table.concat(staged_lines, "\n") .. "\n")
			a.uv.fs_close(fd)

			Job({ cmds = git.add(cline_info.filepath) }):start()

			_, fd = a.uv.fs_open(cline_info.abs_path, "w", 448)
			a.uv.fs_write(fd, ori_content)
			a.uv.fs_close(fd)

			delay_reload()
		end),
	})

	local worktree_buf = ui.FileBuffer(cline_info.abs_path)
	vim.filetype.match(cline_info.abs_path, stage_buf.id)
	vim.filetype.match(cline_info.abs_path, worktree_buf.id)

	grid:add_row({ height = 1 }):fill_window(ui.TitleWindow(ui.Buffer({
		content = { "Stage", cline_info.filepath, "Worktree" },
	})))
	grid:add_row({ focusable = true }):vfill_windows({
		ui.DiffWindow(stage_buf),
		ui.DiffWindow(worktree_buf, { focus_on_open = true }),
	}, true)
	grid:show()
end

function M:diff_index()
	local cline_info = self:parse_line()

	local grid = ui.Grid()
	local not_indexed = git.status_porcelain(cline_info.filepath)[cline_info.filepath].index == "?"
	local index_buf = ui.Buffer({
		filename = ("igit://HEAD:%s"):format(cline_info.filepath),
		content = not_indexed and {} or function()
			return git.show(("HEAD:%s"):format(cline_info.filepath))
		end,
	})
	local worktree_buf = ui.FileBuffer(cline_info.abs_path)
	vim.filetype.match(cline_info.abs_path, index_buf.id)
	vim.filetype.match(cline_info.abs_path, worktree_buf.id)

	grid:add_row({ height = 1 }):fill_window(ui.TitleWindow(ui.Buffer({
		content = { "HEAD", cline_info.filepath, "Worktree" },
	})))
	grid:add_row({ focusable = true }):vfill_windows({
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
	res.filepath = line:find_pattern("[^%s]+%s+([^%s]+)$")
	res.abs_path = path.join(git.find_root(), res.filepath)
	return res
end

function M:open(args, open_cmd)
	args = args or self.options.args
	self:open_or_new_buffer(
		args,
		{
			git_root = git.find_root(),
			type = "status",
		},
		vim.tbl_deep_extend("keep", { open_cmd = open_cmd }, self.options, {
			content = function()
				return git.status(args)
			end,
		})
	)
end

return M
