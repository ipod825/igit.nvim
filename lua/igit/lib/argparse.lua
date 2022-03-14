local M = require 'igit.lib.datatype.Class'()
require 'igit.lib.datatype.std_extension'
local List = require 'igit.lib.datatype.List'
local Dict = require 'igit.lib.datatype.Dict'
local functional = require 'igit.lib.functional'

local ArgType = {POSITION = 1, FLAG = 2, LONG_FLAG = 3}

function M:init(prog, opts)
    opts = opts or {}
    vim.validate({prog = {prog, 'string', true}, opts = {opts, 'table', true}})
    self.prog = prog
    self.sub_parsers = {}
    self.sub_commands_key = opts.sub_commands_key or 'sub_commands'
    self.arg_props = {
        [ArgType.POSITION] = {},
        [ArgType.FLAG] = {},
        [ArgType.LONG_FLAG] = {}
    }
end

function M:add_subparser(prog)
    local sub_parser = M(prog, {sub_commands_key = self.sub_commands_key})
    self.sub_parsers[prog] = sub_parser
    return sub_parser
end

function M:_arg_and_type(str)
    local name, pos = str:gsub('=.*$', '')

    name, pos = str:gsub('^-', '')
    if pos == 0 then return name, ArgType.POSITION end
    name, pos = name:gsub('^-', '')
    if pos == 0 then
        return name, ArgType.FLAG
    else
        return name, ArgType.LONG_FLAG
    end
end

function M:_convert_type(value, type)
    if type == 'string' then
        return tostring(value)
    elseif type == 'number' then
        return tonumber(value)
    end
end

function M:add_argument(provided_name, opts)
    vim.validate({provided_name = {provided_name, 'string'}})
    local arg, arg_type = self:_arg_and_type(provided_name)
    local arg_prop = vim.tbl_extend('keep', opts or {}, {
        name = arg,
        repr = provided_name,
        nargs = 1,
        type = 'string',
        required = (arg_type == ArgType.POSITION)
    })
    if arg_type == ArgType.POSITION then
        assert(arg_prop.required, "position arguments must can't be optional")
        table.insert(self.arg_props[arg_type], arg_prop)
    else
        self.arg_props[arg_type][arg] = arg_prop
    end
end

function M:_is_parsed_args_invalid(parsed_args)
    local flag_arg_props = vim.tbl_extend('error', self.arg_props[ArgType.FLAG],
                                          self.arg_props[ArgType.LONG_FLAG])
    for arg, arg_prop in pairs(flag_arg_props) do
        if arg_prop.required and parsed_args[arg] == nil then
            return ('%s is required'):format(arg_prop.repr)
        end
    end
end

function M:parse(str)
    local _, args = functional.head_tail(str:split())
    local res, err_msg = self:parse_internal(args)
    err_msg = err_msg or self:_is_parsed_args_invalid(res)

    if err_msg then
        vim.notify(('error: %s'):format(err_msg))
        return nil
    end

    return res
end

function M:get_completion_list(str)
    local _, args = functional.head_tail(str:split())
    return self:get_completion_list_internal(args)
end

function M:get_completion_list_internal(args)
    local parsed_res = self:parse_internal(args)

    local sub_commands = parsed_res[self.sub_commands_key] or {}
    local parser = self
    for _, sub_command in ipairs(sub_commands) do
        parser = parser.sub_parsers[sub_command]
    end

    local res = {flags = List(), commands = Dict.keys(parser.sub_parsers)}
    local flag_arg_props = vim.tbl_extend('error',
                                          parser.arg_props[ArgType.FLAG],
                                          parser.arg_props[ArgType.LONG_FLAG])
    for k, arg_prop in pairs(flag_arg_props) do
        if parsed_res[k] == nil then res.flags:append(arg_prop.repr) end
    end
    table.sort(res.flags)
    table.sort(res.commands)
    return res
end

function M:parse_internal(args)
    args = args or {}
    local position_args = List(self.arg_props[ArgType.POSITION]):to_iter()

    local current_arg_prop = nil
    local values = List()
    local res = {}
    for i, token in ipairs(args) do
        if self.sub_parsers[token] then
            local sub_res = self.sub_parsers[token]:parse_internal(
                                vim.list_slice(args, i + 1))
            res = vim.tbl_extend('error', res, sub_res)
            res[self.sub_commands_key] = res[self.sub_commands_key] or {}
            table.insert(res[self.sub_commands_key], 1, token)
            return res
        end
        local arg, arg_type = self:_arg_and_type(token)

        if current_arg_prop == nil then
            if arg_type == ArgType.POSITION then
                values:append(arg)
                current_arg_prop = position_args:next()
                if not current_arg_prop then
                    return res, ('unrecognized arguments: %s'):format(arg)
                end
            else
                local _, value = functional.head_tail(token:split('='))
                if value then
                    values:append(table.concat(value, ''))
                end
                current_arg_prop = self.arg_props[arg_type][arg]
            end
        else
            values:append(arg)
        end

        if #values >= current_arg_prop.nargs then
            res[current_arg_prop.name] =
                values:map(function(e)
                    return self:_convert_type(e, current_arg_prop.type)
                end):collect():unbox_if_one()
            current_arg_prop = nil
            values = List()
        end
    end

    return res
end

return M
