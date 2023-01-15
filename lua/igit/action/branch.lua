local M = {}
local Buffer = require("libp.ui.Buffer")
local git = require("igit.git")
local vimfn = require("libp.utils.vimfn")
local Job = require("libp.Job")
local iter = require("libp.iter")
local Set = require("libp.datatype.Set")
local reference_action = require("igit.action.reference")
local common_action = require("igit.action.common")

function M.rename()
    Buffer.get_current_buffer():edit({
        get_items = function()
            return M.get_branches_in_rows(1, vim.fn.line("$"))
        end,
        update = function(ori_items, new_items)
            if #ori_items ~= #new_items then
                vimfn.warn("Can't remove or add items!")
                return
            end
            for i = 1, #ori_items do
                local intermediate = ("%s-igitrename"):format(ori_items[i])
                Job({ cmd = git.branch("-m", ori_items[i], intermediate) }):start()
            end
            for i = 1, #ori_items do
                local intermediate = ("%s-igitrename"):format(ori_items[i])
                Job({ cmd = git.branch("-m", intermediate, new_items[i]) }):start()
            end
        end,
    })
end

function M.mark()
    Buffer.get_current_buffer():mark({ branch = M.parse_line().branch }, 2)
end

function M.show()
    reference_action.show(M.parse_line().branch)
end

function M.rebase_chain()
    reference_action.rebase_branches({
        current_buf = Buffer.get_current_buffer(),
        ori_reference = Job({ cmd = git.branch("--show-current") }):stdoutputstr(),
        branches = M.get_branches_in_rows(vimfn.visual_rows()),
        base_reference = M.get_primary_mark_or_current_branch(),
        grafted_ancestor = M.get_secondary_mark_branch() or "",
    })
end

function M.parse_line(linenr)
    linenr = linenr or "."
    local line = vim.fn.getline(linenr)
    local res = { is_current = false, branch = nil }
    res.is_current = line:find_pattern("%s*(%*?)") ~= ""
    res.branch = line:find_pattern("(HEAD) detached") or line:find_pattern("%s?([^%s%*]+)%s?")
    return res
end

function M.switch()
    common_action.runasync_and_reload(git.checkout(M.parse_line().branch))
end

function M.reset()
    reference.reset(Job({ cmd = git.branch("--show-current") }):stdoutputstr(), M.parse_line().branch)
end

function M.get_primary_mark_or_current_branch()
    local mark = Buffer.get_current_buffer().ctx.mark
    local res = mark and mark[1].branch or Job({ cmd = git.branch("--show-current") }):stdoutputstr()
    res = #res > 0 and res or "HEAD"
    return res
end

function M.get_secondary_mark_branch()
    local mark = Buffer.get_current_buffer().ctx.mark
    return mark and mark[2] and mark[2].branch
end

function M.get_anchor()
    local mark = Buffer.get_current_buffer().ctx.mark
    return {
        base = mark and mark[1].branch or Job({ cmd = git.branch("--show-current") }):stdoutputstr(),
        grafted_ancestor = mark and mark[2] and mark[2].branch,
    }
end

function M.get_branches_in_rows(row_beg, row_end)
    return iter.range(row_beg, row_end)
        :map(function(e)
            return M.parse_line(e).branch
        end)
        :filter(function(e)
            return e ~= "HEAD"
        end)
        :collect()
end

function M.new_branch()
    local base_branch = M.get_primary_mark_or_current_branch()
    Buffer.get_current_buffer():edit({
        get_items = function()
            return Set(M.get_branches_in_rows(vimfn.all_rows()))
        end,
        update = function(ori_branches, new_branches)
            for new_branch in Set.values(new_branches - ori_branches) do
                Job({ cmd = git.branch(new_branch, base_branch) }):start()
            end
        end,
    })
    vim.cmd("normal! o")
    vim.cmd("startinsert")
end

function M.force_delete_branch()
    local cmds = M.get_branches_in_rows(vimfn.visual_rows()):map(function(b)
        return git.branch("-D", b)
    end)
    common_action.runasync_all_and_reload(cmds)
end

return M
