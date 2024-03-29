local M = {}
local a = require("plenary.async")
local git = require("igit.git")
local ui = require("libp.ui")
local Job = require("libp.Job")
local vimfn = require("libp.utils.vimfn")
local default_config = require("igit.default_config")
local iter = require("libp.iter")

function M.setup(opts)
    opts = vim.tbl_deep_extend("force", default_config, opts or {})

    vim.validate({
        command = { opts.command, "s", true },
    })

    M.log = require("igit.page.Log")():setup(opts.log)
    M.branch = require("igit.page.Branch")():setup(opts.branch)
    M.status = require("igit.page.Status")():setup(opts.status)
    M.blame = require("igit.page.Blame")():setup(opts.blame)
    M.define_command(opts)
end

function M.define_command(opts)
    vim.validate({ command = { opts.command, "s" }, git_sub_commands = { opts.git_sub_commands, "t" } })

    local EchoParser = require("libp.argparse.EchoParser")
    local parser = require("libp.argparse.Parser")(opts.command)

    parser:add_subparser(EchoParser("branch"))
    parser:add_subparser(EchoParser("log"))
    parser:add_subparser(EchoParser("status"))
    parser:add_subparser(EchoParser("blame"))

    parser:add_subparser(EchoParser("add"):add_argument("--all"):add_argument("-u"))
    parser:add_subparser(EchoParser("checkout"))
    parser:add_subparser(EchoParser("clone"))
    parser:add_subparser(EchoParser("commit"))
    parser:add_subparser(EchoParser("diff"))
    parser:add_subparser(EchoParser("fetch"))
    parser:add_subparser(EchoParser("grep"))
    parser:add_subparser(EchoParser("init"))
    parser:add_subparser(EchoParser("merge"))
    parser:add_subparser(EchoParser("pull"))
    parser:add_subparser(EchoParser("push"))
    parser:add_subparser(EchoParser("rebase"):add_argument("--continue"):add_argument("--abort"))
    parser:add_subparser(EchoParser("remote"))
    parser:add_subparser(EchoParser("reset"):add_argument("--hard"):add_argument("--soft"):add_argument("--mixed"))
    parser:add_subparser(EchoParser("revert"))
    parser:add_subparser(EchoParser("rev-parse"))
    parser:add_subparser(EchoParser("stash"))
    parser:add_subparser(EchoParser("tag"))

    local complete = function(arg_lead, cmd_line, cursor_pos)
        local beg = cmd_line:find(" ")
        return parser:get_completion_list(cmd_line:sub(beg, #cmd_line), arg_lead)
    end

    local execute = function(opts)
        a.void(function()
            local args = parser:parse(opts.args, true)
            if not args then
                return
            end

            if #args == 0 then
                table.insert(args.git_cmds, 1, "git")
                Job({
                    cmd = args.git_cmds,
                    on_stdout = function(lines)
                        vimfn.info(table.concat(lines, "\n"))
                    end,
                }):start()
                return
            end

            assert(#args == 2)
            local module, module_args = unpack(args[2])

            if #module_args == 0 then
                module_args = nil
            end

            if M[module] and not opts.bang then
                local open_cmd = #opts.mods > 0 and opts.mods .. " split" or nil
                M[module]:open(module_args, open_cmd)
            else
                local gita = git.with_default_args({ no_color = true })
                local current_buf = ui.Buffer.get_current_buffer()
                Job({
                    cmd = gita[module](module_args),
                    stderr_dump_level = Job.StderrDumpLevel.ALWAYS,
                    on_stdout = function(lines)
                        vimfn.info(table.concat(lines, "\n"))
                    end,
                }):start()

                if current_buf and vim.b[current_buf.id].git_root then
                    current_buf:reload()
                end
            end
        end)()
    end

    vim.api.nvim_create_user_command(opts.command, execute, {
        nargs = "+",
        bang = true,
        complete = complete,
    })
end

return M
