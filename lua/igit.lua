local M = {}
require('igit.lib.datatype.std_extension')
local git = require('igit.git.git')
local global = require('igit.global')

function M.setup(options)
    global.logger = require('igit.lib.debug.logger')(options)
    M.log = require('igit.page.Log')(options)
    M.branch = require('igit.page.Branch')(options)
    M.status = require('igit.page.Status')(options)
    M.git_cmds = {'stash'}
    M.define_command()
end

function M.define_command()
    local PipeParser = require 'igit.lib.argparse.PipeParser'
    local parser = require 'igit.lib.argparse.Parser'('IGit')
    parser:add_argument('--open_cmd')
    parser:add_subparser(PipeParser('branch'))
    parser:add_subparser(PipeParser('log'))
    parser:add_subparser(PipeParser('status'))
    for _, cmd in ipairs(M.git_cmds) do parser:add_subparser(PipeParser(cmd)) end

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
        elseif M.git_cmds[module] then
            git[module](module_args)
        end
    end

    vim.api.nvim_add_user_command('IGit', execute,
                                  {nargs = '+', complete = complete})
end

return M
