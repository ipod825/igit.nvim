local M = require("libp.datatype.Class"):EXTEND()
local pathfn = require("libp.utils.pathfn")
local Set = require("libp.datatype.Set")
local Job = require("libp.Job")
local vimfn = require("libp.utils.vimfn")
local Buffer = require("libp.ui.AnsiColorBuffer")
local git = require("igit.git")

local ui = require("libp.ui")

local buffer_index = vim.defaulttable(function() return Set() end)

function M:open(opts)
    local git_root = git.find_root()
    if git_root == nil or git_root == "" then
        vimfn.warn("No git project found!")
        return
    end

    vim.validate({
        args = { opts.args, "t" },
        cmd = { opts.cmd, "s" },
    })

    local name = table.concat(opts.args, "")
    local index

    if Set.has(buffer_index[opts.cmd], name) then
        index = buffer_index[opts.cmd][name]
    else
        index = Set.size(buffer_index[opts.cmd])
        Set.add(buffer_index[opts.cmd], name, (index == 0) and "" or tostring(index))
    end

    opts = vim.tbl_deep_extend("force", {
        open_cmd = "tab drop",
        content = function()
            return git.with_default_args({ git_dir = git_root })[opts.cmd](opts.args)
        end,
        filename = ("igit://%s-%s%s"):format(pathfn.basename(git_root), opts.cmd, buffer_index[opts.cmd][name]),
        b = { git_root = git_root },
        bo = {
            filetype = "igit",
            bufhidden = "hide",
        },
    }, opts)

    local buffer
    if #opts.open_cmd == 0 then
        buffer = Buffer:get_or_new(opts)
        local grid = ui.Grid()
        grid:add_row({ focusable = true }):fill_window(ui.Window(buffer, { focus_on_open = true }))
        grid:show()
    else
        buffer = Buffer:open_or_new(opts)
    end

    vim.cmd("lcd " .. git_root)
    return buffer
end

function M:current_buf()
    return Buffer.get_current_buffer()
end

function M:runasync_and_reload(cmd)
    local current_buf = self:current_buf()
    Job({ cmd = cmd }):start()
    current_buf:reload()
end

function M:runasync_all_and_reload(cmds)
    local current_buf = self:current_buf()
    Job.start_all(cmds)
    current_buf:reload()
end

return M
