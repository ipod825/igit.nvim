local M = {}
require('igit.libp.datatype.std_extension')
local git = require('igit.git.git')
local Set = require('igit.libp.datatype.Set')
local job = require('igit.libp.job')

function M.setup(opts)
    require('igit.log'):config(opts)
    M.log = require('igit.page.Log')(opts)
    M.branch = require('igit.page.Branch')(opts)
    M.status = require('igit.page.Status')(opts)
    M.git_cmds = Set({'stash'})
    M.define_command()
end

function M.define_command()
    local PipeParser = require 'igit.libp.argparse.PipeParser'
    local parser = require 'igit.libp.argparse.Parser'('IGit')
    parser:add_argument('--open_cmd')
    parser:add_subparser(PipeParser('branch'))
    parser:add_subparser(PipeParser('log'))
    parser:add_subparser(PipeParser('status'))
    for cmd in M.git_cmds:values() do parser:add_subparser(PipeParser(cmd)) end

    local complete = function(arg_lead, cmd_line, cursor_pos)
        return parser:get_completion_list(cmd_line, arg_lead)
    end

    local execute = function(opts)
        local args = parser:parse(opts.args, true)
        if not args then return end

        if #args <= 1 then
            vim.notify('Not enough arguments!')
            return
        end
        assert(#args == 2)
        local module, module_args = unpack(args[2])

        if #module_args == 0 then module_args = nil end
        if M[module] then
            M[module]:open(module_args)
        elseif Set.has(M.git_cmds, module) then
            job.jobstart(git[module](module_args), {
                on_stdout = function(lines)
                    vim.notify(table.concat(lines, '\n'))
                end
            })

        end
    end

    vim.api.nvim_add_user_command('IGit', execute,
                                  {nargs = '+', complete = complete})
end

return M
