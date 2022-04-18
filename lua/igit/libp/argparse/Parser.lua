require("igit.libp.utils.string_extension")
local M = require("igit.libp.datatype.Class"):EXTEND()
local List = require("igit.libp.datatype.List")
local OrderedDict = require("igit.libp.datatype.OrderedDict")
local functional = require("igit.libp.functional")
local tokenize = require("igit.libp.argparse.tokenizer").tokenize
local log = require("igit.libp.log")

local ArgType = { POSITION = 1, FLAG = 2, LONG_FLAG = 3 }

local function arg_and_type(str)
	local name, pos = str:gsub("(-[^=]+)=.*$", "%1")

	name, pos = name:gsub("^-", "")
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

local function convert_type(value, type)
	if type == "string" then
		return tostring(value)
	elseif type == "number" then
		return tonumber(value)
	end
end

function M:init(prog)
	vim.validate({ prog = { prog, "string", true } })
	self.prog = prog or ""
	self.sub_parsers = {}
	self.arg_props = {
		[ArgType.POSITION] = OrderedDict(),
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

function M:add_argument(provided_name, opts)
	vim.validate({ provided_name = { provided_name, "string" }, opts = { opts, "table", true } })
	opts = opts or {}

	local arg, arg_type = arg_and_type(provided_name)

	if arg_type == ArgType.POSITION and opts.required == nil and opts.nargs ~= "*" then
		opts.required = true
	end

	local arg_prop = vim.tbl_extend("keep", opts, {
		name = arg,
		repr = provided_name,
		nargs = 1,
		type = "string",
	})
	self.arg_props[arg_type][arg] = arg_prop
end

function M:is_parsed_args_invalid(parsed_res, check_positional)
	vim.validate({ parsed_res = { parsed_res, "table" }, check_positional = { check_positional, "boolean", true } })
	local arg_props = check_positional
			and vim.tbl_extend(
				"error",
				OrderedDict.data(self.arg_props[ArgType.POSITION]),
				self.arg_props[ArgType.FLAG],
				self.arg_props[ArgType.LONG_FLAG]
			)
		or vim.tbl_extend("error", self.arg_props[ArgType.FLAG], self.arg_props[ArgType.LONG_FLAG])

	for arg, arg_prop in pairs(arg_props) do
		if parsed_res[arg] == nil then
			if arg_prop.required then
				return ("%s is required"):format(arg_prop.repr)
			elseif arg_prop.nargs == "+" then
				return ("%s requires at least one argument"):format(arg_prop.repr)
			end
		else
			local num_parsed = type(parsed_res[arg]) == "table" and #parsed_res[arg] or 1
			if type(arg_prop.nargs) == "number" and num_parsed < arg_prop.nargs then
				return ("%s requires %d argument"):format(arg_prop.repr, arg_prop.nargs)
			elseif arg_prop.nargs == "+" and num_parsed < 1 then
				return ("%s requires at least one argument"):format(arg_prop.repr)
			end
		end
	end

	return false
end

function M:parse(str)
	vim.validate({ str = { str, "string" } })
	local tokens = tokenize(str)
	if not tokens then
		return nil
	end
	local res, err_msg = self:parse_internal(tokens)

	local parser
	for i = 1, #res do
		parser = parser and parser.sub_parsers[res[i][1]] or self
		err_msg = err_msg or parser:is_parsed_args_invalid(res[i][2], true)
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
	local tokens = tokenize(str)
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
	local next_position_args = OrderedDict.values(self.arg_props[ArgType.POSITION])

	local current_arg_prop = nil
	local values = List()
	local res = {}

	local function fill_current_arg_prop_with_values()
		res[current_arg_prop.name] = values
			:to_iter()
			:map(function(e)
				return convert_type(e, current_arg_prop.type)
			end)
			:collect()
			:unbox_if_one()
		current_arg_prop = nil
		values = List()
	end

	for i, token in ipairs(args) do
		if self.sub_parsers[token] then
			local sub_res = self.sub_parsers[token]:parse_internal(vim.list_slice(args, i + 1))
			res = { { self.prog, res } }
			vim.list_extend(res, sub_res)
			return res
		end
		local arg, arg_type = arg_and_type(token)

		if current_arg_prop == nil then
			if arg_type == ArgType.POSITION then
				values:append(arg)
				current_arg_prop = next_position_args()
			else
				local value = token:find_pattern(arg .. "=(.*)")
				if value then
					values:append(value)
				end
				current_arg_prop = self.arg_props[arg_type][arg]
			end
		elseif arg_type ~= ArgType.POSITION then
			fill_current_arg_prop_with_values()
			local value = token:find_pattern(arg .. "=(.*)")
			if value then
				values:append(value)
			end
			current_arg_prop = self.arg_props[arg_type][arg]
		else
			values:append(arg)
		end

		if not current_arg_prop then
			return res, ("unrecognized arguments: %s"):format(arg)
		elseif type(current_arg_prop.nargs) == "number" and #values >= current_arg_prop.nargs then
			fill_current_arg_prop_with_values()
		end
	end

	-- Fill partial result, which can be used by get_completion_list.
	if current_arg_prop and not res[current_arg_prop.name] then
		fill_current_arg_prop_with_values()
	end

	return { { self.prog, res } }
end

return M
