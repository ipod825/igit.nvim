require("igit.libp.utils.string_extension")
local M = require("igit.libp.datatype.Class"):EXTEND()
local List = require("igit.libp.datatype.List")
local functional = require("igit.libp.functional")
local term_utils = require("igit.libp.utils.term")
local log = require("igit.libp.log")

local ArgType = { _POSITION_DICT = 1, POSITION = 2, FLAG = 3, LONG_FLAG = 4 }

function M:init(prog)
	vim.validate({ prog = { prog, "string", true } })
	self.prog = prog or ""
	self.sub_parsers = {}
	self.arg_props = {
		[ArgType._POSITION_DICT] = {},
		[ArgType.POSITION] = {},
		[ArgType.FLAG] = {},
		[ArgType.LONG_FLAG] = {},
	}
end

function M:add_subparser(prog)
	local sub_parser
	if type(prog) == "string" then
		sub_parser = M(prog)
	else
		sub_parser = prog
		prog = sub_parser.prog
		assert(prog, "subparser prog can't be nil!")
	end
	self.sub_parsers[prog] = sub_parser
	return sub_parser
end

function M:_arg_and_type(str)
	local name, pos = str:gsub("=.*$", "")

	name, pos = str:gsub("^-", "")
	if pos == 0 then
		return name, ArgType.POSITION
	end
	name, pos = name:gsub("^-", "")
	if pos == 0 then
		return name, ArgType.FLAG
	else
		return name, ArgType.LONG_FLAG
	end
end

function M:_convert_type(value, type)
	if type == "string" then
		return tostring(value)
	elseif type == "number" then
		return tonumber(value)
	end
end

function M:add_argument(provided_name, opts)
	vim.validate({ provided_name = { provided_name, "string" } })

	local arg, arg_type = self:_arg_and_type(provided_name)
	local arg_prop = vim.tbl_extend("keep", opts or {}, {
		name = arg,
		repr = provided_name,
		nargs = 1,
		type = "string",
		required = (arg_type == ArgType.POSITION),
	})
	if arg_type == ArgType.POSITION then
		assert(arg_prop.required, "position arguments must can't be optional")
		table.insert(self.arg_props[arg_type], arg_prop)
		self.arg_props[ArgType._POSITION_DICT][arg] = arg_prop
	else
		self.arg_props[arg_type][arg] = arg_prop
	end
end

function M:is_parsed_args_invalid(parsed_res)
	local arg_props = vim.tbl_extend(
		"error",
		self.arg_props[ArgType._POSITION_DICT],
		self.arg_props[ArgType.FLAG],
		self.arg_props[ArgType.LONG_FLAG]
	)
	for arg, arg_prop in pairs(arg_props) do
		if parsed_res[arg] == nil then
			if arg_prop.required then
				return ("%s is required"):format(arg_prop.repr)
			end
		else
			local num_parsed = type(parsed_res[arg]) == "table" and #parsed_res[arg] or 1
			if num_parsed < arg_prop.nargs then
				return ("%s requires %d argument"):format(arg_prop.repr, arg_prop.nargs)
			end
		end
	end

	return false
end

function M:parse(str)
	vim.validate({ str = { str, "string" } })
	local tokens = term_utils.tokenize_command(str)
	if not tokens then
		return nil
	end
	local res, err_msg = self:parse_internal(tokens)

	local parser
	for i = 1, #res do
		parser = parser and parser.sub_parsers[res[i][1]] or self
		err_msg = err_msg or parser:is_parsed_args_invalid(res[i][2])
	end

	if err_msg then
		vim.notify(("error: %s"):format(err_msg))
		return nil
	end

	if #res == 1 then
		return res[1][2]
	end
	return res
end

function M:get_completion_list(str, hint)
	local tokens = term_utils.tokenize_command(str)
	return self:get_completion_list_internal(tokens, hint)
end

function M:get_completion_list_internal(args, hint)
	local full_parsed_res, err = self:parse_internal(args)

	local parser
	for i = 1, #full_parsed_res do
		parser = parser and parser.sub_parsers[full_parsed_res[i][1]] or self
	end

	local parsed_res = err and {} or full_parsed_res[#full_parsed_res][2]
	if parser:is_parsed_args_invalid(parsed_res) then
		return {}
	end

	local res = List(vim.tbl_keys(parser.sub_parsers))
	local flag_arg_props = vim.tbl_extend("error", parser.arg_props[ArgType.FLAG], parser.arg_props[ArgType.LONG_FLAG])
	for k, arg_prop in pairs(flag_arg_props) do
		if parsed_res[k] == nil then
			res:append(arg_prop.repr)
		end
	end

	if hint then
		res = res
			:to_iter()
			:filter(function(e)
				return e:startswith(hint)
			end)
			:collect()
	end
	table.sort(res)
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
			local sub_res = self.sub_parsers[token]:parse_internal(vim.list_slice(args, i + 1))
			res = { { self.prog, res } }
			vim.list_extend(res, sub_res)
			return res
		end
		local arg, arg_type = self:_arg_and_type(token)

		if current_arg_prop == nil then
			if arg_type == ArgType.POSITION then
				values:append(arg)
				current_arg_prop = position_args:next()
			else
				local _, value = functional.head_tail(token:split_trim("="))
				if value then
					values:append(table.concat(value, ""))
				end
				current_arg_prop = self.arg_props[arg_type][arg]
			end

			if not current_arg_prop then
				return res, ("unrecognized arguments: %s"):format(arg)
			end
		else
			values:append(arg)
		end

		if #values >= current_arg_prop.nargs then
			res[current_arg_prop.name] = values
				:to_iter()
				:map(function(e)
					return self:_convert_type(e, current_arg_prop.type)
				end)
				:collect()
				:unbox_if_one()
			current_arg_prop = nil
			values = List()
		end
	end

	if current_arg_prop and not res[current_arg_prop.name] then
		res[current_arg_prop.name] = values
			:to_iter()
			:map(function(e)
				return self:_convert_type(e, current_arg_prop.type)
			end)
			:collect()
			:unbox_if_one()
	end

	return { { self.prog, res } }
end

return M
