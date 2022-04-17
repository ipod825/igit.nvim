require("igit.libp.utils.string_extension")
local M = require("igit.page.ReferencePage"):EXTEND()
local git = require("igit.git")
local Job = require("igit.libp.job")
local IterList = require("igit.libp.datatype.IterList")
local term_utils = require("igit.libp.utils.term")
local ui = require("igit.libp.ui")
local vimfn = require("igit.libp.utils.vimfn")
local log = require("igit.log")

function M:setup(options)
	vim.validate({ options = { options, "table" } })

	self.options = vim.tbl_deep_extend("force", {
		mappings = {
			n = {
				["<cr>"] = self:BIND(self.switch),
				["m"] = { callback = self:BIND(self.mark), modify_buffer = false },
				["r"] = self:BIND(self.rebase_interactive),
				["s"] = self:BIND(self.show),
				["R"] = self:BIND(self.reset),
			},
			v = { ["r"] = self:BIND(self.rebase_chain) },
		},
	}, options)
	return self
end

function M:switch()
	local reference = self:select_reference(self:parse_line().references, "Checkout")
	self:runasync_and_reload(git.checkout(reference))
end

function M:reset()
	self
		:SUPER()
		:reset(self:get_current_branch_or_sha(), self:select_reference(self:parse_line().references, "Checkout"))
end

function M:mark()
	local references = self:parse_line().references
	assert(#references >= 1)
	self:current_buf():mark({ reference = references[1] }, 1)
end

function M:get_anchor_branch()
	local mark = self:current_buf().ctx.mark
	return {
		base = mark and mark[1].branch or Job({ cmds = git.branch("--show-current") }):stdoutputstr(),
	}
end

function M:get_current_branch_or_sha()
	local branch = Job({ cmds = git.branch("--show-current") }):stdoutputstr()
	if branch ~= "" then
		return branch
	end
	return Job({ cmds = git["rev-parse"]("HEAD") }):stdoutputstr()
end

function M:get_primary_mark_or_current_reference()
	local mark = self:current_buf().ctx.mark
	return mark and mark[1].reference or self:get_current_branch_or_sha()
end

function M:get_branches_in_rows(row_beg, row_end)
	return IterList.from_range(row_beg, row_end)
		:map(function(e)
			return self:parse_line(e).branches
		end)
		:filter(function(e)
			return #e == 2
		end)
		:map(function(e)
			return e[0]
		end)
		:collect()
end

function M:show()
	self:SUPER():show(self:parse_line().sha)
end

function M:rebase_interactive()
	local delay_reload = self.buf_enter_reload and nil or self:current_buf():delay_reload()

	Job({ cmds = git.rebase("-i", self:parse_line(row_beg).sha) }):start()

	if delay_reload then
		delay_reload()
	end
end

function M:rebase_chain()
	local row_beg, row_end = vimfn.visual_rows()
	local branches = {}

	local first_row_references = self:parse_line(row_beg).references
	if #first_row_references <= 1 then
		ui.InfoBox({
			content = ("No branch for %s at the first selected line %d!"):format(first_row_references[1], row_beg),
		}):show()
		return
	end

	for i = row_end, row_beg, -1 do
		local reference = self:select_reference(self:parse_line(i).branches, "Rebase Pick Branch")
		if reference then
			table.insert(branches, reference)
		end
	end

	self:rebase_branches({
		current_buf = self:current_buf(),
		ori_reference = Job({ cmds = git.branch("--show-current") }):stdoutputstr(),
		branches = branches,
		base_reference = self:get_primary_mark_or_current_reference(),
		grafted_ancestor = Job({ cmds = git["rev-parse"](("%s^1"):format(self:parse_line(row_end).sha)) }):stdoutputstr(),
	})
end

function M:select_reference(references, op_title)
	if #references < 2 then
		return references[1]
	end
	return ui.Menu({
		title = ("%s Commit"):format(op_title),
		content = references,
	}):select()
end

function M:parse_line(linenr)
	linenr = linenr or "."
	local line = term_utils.remove_ansi_escape(vim.fn.getline(linenr))
	local res = {}
	res.sha = line:find_pattern("([a-f0-9]+)%s")
	local branch_candidates = line:find_pattern("%((.-)%)")
	res.branches = branch_candidates
			and vim.tbl_filter(function(e)
				return #e > 0 and e ~= "->" and e ~= "HEAD"
			end, branch_candidates:split_trim("[, ]"))
		or {}
	res.references = vim.deepcopy(res.branches)
	table.insert(res.references, res.sha)
	res.author = line:find_pattern("%s(<.->)%s")
	return res
end

function M:open(args, open_cmd)
	args = args or self.options.args
	self:open_or_new_buffer(
		args,
		{
			git_root = git.find_root(),
			type = "log",
		},
		vim.tbl_deep_extend("keep", { open_cmd = open_cmd }, self.options, {
			-- Log page can have too many lines, wiping it on hidden saves memory.
			bo = { bufhidden = "wipe" },
			content = function()
				return git.log(args)
			end,
		})
	)
end

return M
