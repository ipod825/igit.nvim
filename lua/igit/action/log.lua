require("libp.utils.string_extension")
local M = require("igit.page.ReferencePage"):EXTEND()
local git = require("igit.git")
local Job = require("libp.Job")
local Buffer = require("libp.ui.Buffer")
local iter = require("libp.iter")
local ui = require("libp.ui")
local vimfn = require("libp.utils.vimfn")
local reference_action = require("igit.action.reference")
local common_action = require("igit.action.common")

function M.switch()
    local reference = M.select_reference(M.parse_line().references, "Checkout")
    common_action.runasync_and_reload(git.checkout(reference))
end

function M.reset()
    reference_action.reset(M.get_current_branch_or_sha(), M.select_reference(M.parse_line().references, "Checkout"))
end

function M.mark()
    local references = M.parse_line().references
    assert(#references >= 1)
    Buffer.get_current_buffer():mark({ reference = references[1] }, 1)
end

function M.get_anchor_branch()
    local mark = Buffer.get_current_buffer().ctx.mark
    return {
        base = mark and mark[1].branch or Job({ cmd = git.branch("--show-current") }):stdoutputstr(),
    }
end

function M.get_current_branch_or_sha()
    local branch = Job({ cmd = git.branch("--show-current") }):stdoutputstr()
    if branch ~= "" then
        return branch
    end
    return Job({ cmd = git["rev-parse"]("HEAD") }):stdoutputstr()
end

function M.get_primary_mark_or_current_reference()
    local mark = Buffer.get_current_buffer().ctx.mark
    return mark and mark[1].reference or M.get_current_branch_or_sha()
end

function M.get_branches_in_rows(row_beg, row_end)
    return iter.range(row_beg, row_end)
        :map(function(e)
            return M.parse_line(e).branches
        end)
        :filter(function(e)
            return #e == 2
        end)
        :map(function(e)
            return e[0]
        end)
        :collect()
end

function M.show()
    reference_action.show(M.parse_line().sha)
end

function M.rebase_interactive()
    common_action.runasync_and_reload(git.rebase("-i", M.parse_line(vimfn.getrow()).sha))
end

function M.rebase_chain()
    local row_beg, row_end = vimfn.visual_rows()
    local branches = {}

    local first_row_references = M.parse_line(row_beg).references
    if #first_row_references <= 1 then
        ui.InfoBox({
            content = ("No branch for %s at the first selected line %d!"):format(first_row_references[1], row_beg),
        }):show()
        return
    end

    for i = row_end, row_beg, -1 do
        local reference = M.select_reference(M.parse_line(i).branches, "Rebase Pick Branch")
        if reference then
            table.insert(branches, reference)
        end
    end

    reference_action.rebase_branches({
        current_buf = Buffer.get_current_buffer(),
        ori_reference = Job({ cmd = git.branch("--show-current") }):stdoutputstr(),
        branches = branches,
        base_reference = M.get_primary_mark_or_current_reference(),
        grafted_ancestor = Job({ cmd = git["rev-parse"](("%s^1"):format(M.parse_line(row_end).sha)) }):stdoutputstr(),
    })
end

function M.select_reference(references, op_title)
    if #references < 2 then
        return references[1]
    end
    return ui.Menu({
        title = ("%s Commit"):format(op_title),
        content = references,
    }):select()
end

function M.parse_line(linenr)
    linenr = linenr or "."
    local line = vim.fn.getline(linenr)
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

return M
