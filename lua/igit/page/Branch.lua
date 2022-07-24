local M = require("igit.page.ReferencePage"):EXTEND()
local git = require("igit.git")
local vimfn = require("libp.utils.vimfn")
local term_utils = require("libp.utils.term")
local Job = require("libp.Job")
local IterList = require("libp.datatype.IterList")
local Set = require("libp.datatype.Set")

function M:setup(options)
	vim.validate({ options = { options, "t" } })

	self.options = vim.tbl_deep_extend("force", {
		mappings = {
			n = {
				["<cr>"] = self:BIND(self.switch),
				["i"] = self:BIND(self.rename),
				["m"] = { callback = self:BIND(self.mark), modify_buffer = false },
				["r"] = self:BIND(self.rebase_chain),
				["o"] = self:BIND(self.new_branch),
				["X"] = self:BIND(self.force_delete_branch),
				["s"] = self:BIND(self.show),
				["R"] = self:BIND(self.reset),
			},
			v = {
				["r"] = self:BIND(self.rebase_chain),
				["X"] = self:BIND(self.force_delete_branch),
			},
		},
	}, options)
	return self
end

function M:rename()
	self:current_buf():edit({
		get_items = function()
			return self:get_branches_in_rows(1, vim.fn.line("$"))
		end,
		fill_lines = function()
			vim.cmd("substitute/\\e\\[[0-9;]*m//g")
		end,
		update = function(ori_items, new_items)
			if #ori_items ~= #new_items then
				vim.notify("Can't remove or add items!")
				return
			end
			for i = 1, #ori_items do
				local intermediate = ("%s-igitrename"):format(ori_items[i])
				Job({ cmds = git.branch("-m", ori_items[i], intermediate) }):start()
			end
			for i = 1, #ori_items do
				local intermediate = ("%s-igitrename"):format(ori_items[i])
				Job({ cmds = git.branch("-m", intermediate, new_items[i]) }):start()
			end
		end,
	})
end

function M:mark()
	self:current_buf():mark({ branch = self:parse_line().branch }, 2)
end

function M:show()
	self:SUPER():show(self:parse_line().branch)
end

function M:rebase_chain()
	self:rebase_branches({
		current_buf = self:current_buf(),

		ori_reference = Job({ cmds = git.branch("--show-current") }):stdoutputstr(),
		branches = self:get_branches_in_rows(vimfn.visual_rows()),
		base_reference = self:get_primary_mark_or_current_branch(),
		grafted_ancestor = self:get_secondary_mark_branch() or "",
	})
end

function M:parse_line(linenr)
	linenr = linenr or "."
	local line = term_utils.remove_ansi_escape(vim.fn.getline(linenr))
	local res = { is_current = false, branch = nil }
	res.is_current = line:find_pattern("%s*(%*?)") ~= ""
	res.branch = line:find_pattern("(HEAD) detached") or line:find_pattern("%s?([^%s%*]+)%s?")
	return res
end

function M:switch()
	self:runasync_and_reload(git.checkout(self:parse_line().branch))
end

function M:reset()
	self:SUPER():reset(Job({ cmds = git.branch("--show-current") }):stdoutputstr(), self:parse_line().branch)
end

function M:get_primary_mark_or_current_branch()
	local mark = self:current_buf().ctx.mark
	local res = mark and mark[1].branch or Job({ cmds = git.branch("--show-current") }):stdoutputstr()
	res = #res > 0 and res or "HEAD"
	return res
end

function M:get_secondary_mark_branch()
	local mark = self:current_buf().ctx.mark
	return mark and mark[2] and mark[2].branch
end

function M:get_anchor()
	local mark = self:current_buf().ctx.mark
	return {
		base = mark and mark[1].branch or Job({ cmds = git.branch("--show-current") }):stdoutputstr(),
		grafted_ancestor = mark and mark[2] and mark[2].branch,
	}
end

function M:get_branches_in_rows(row_beg, row_end)
	return IterList.from_range(row_beg, row_end)
		:map(function(e)
			return self:parse_line(e).branch
		end)
		:filter(function(e)
			return e ~= "HEAD"
		end)
		:collect()
end

function M:new_branch()
	local base_branch = self:get_primary_mark_or_current_branch()
	self:current_buf():edit({
		get_items = function()
			return Set(self:get_branches_in_rows(vimfn.all_rows()))
		end,
		fill_lines = function()
			vim.cmd("substitute/\\e\\[[0-9;]*m//g")
		end,
		update = function(ori_branches, new_branches)
			for new_branch in Set.values(new_branches - ori_branches) do
				Job({ cmds = git.branch(new_branch, base_branch) }):start()
			end
		end,
	})
	vim.cmd("normal! o")
	vim.cmd("startinsert")
end

function M:force_delete_branch()
	local cmds = self:get_branches_in_rows(vimfn.visual_rows()):map(function(b)
		return git.branch("-D", b)
	end)
	self:runasync_all_and_reload(cmds)
end

function M:open(args, open_cmd)
	args = args or self.options.args
	self:open_or_new_buffer(
		args,
		{
			git_root = git.find_root(),
			type = "branch",
		},
		vim.tbl_deep_extend("keep", { open_cmd = open_cmd }, self.options, {
			content = function()
				return git.branch(args)
			end,
		})
	)
end

return M
