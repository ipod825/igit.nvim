local String = getmetatable("").__index
local log = require("igit.libp.log")

function String:trim()
	return (self:gsub("^%s*(.-)%s*$", "%1"))
end

function String:split_trim(sep)
	local res = {}
	for _, s in ipairs(self:split(sep)) do
		table.insert(res, s:trim())
	end
	return res
end

function String:split(sep)
	if #self == 0 then
		return {}
	end
	sep = sep or " "
	local res = {}
	local beg = 1
	local sep_is_space = sep == " "
	if sep_is_space then
		beg = self:find("[^ ]")
		sep = " +"
	end

	while true do
		local sep_beg, sep_end = self:find(sep, beg)
		if sep_beg then
			table.insert(res, self:sub(beg, sep_beg - 1))
			beg = sep_end + 1
		else
			if not sep_is_space or beg <= #self then
				table.insert(res, self:sub(beg, #self))
			end
			return res
		end
	end
end

function String:unquote()
	local res = self:gsub('^"(.+)"$', "%1")
	res = res:gsub("^'(.+)'$", "%1")
	return res
end

function String:find_str(pattern)
	return select(3, self:find(pattern))
end

function String:endswith(s)
	return self:sub(-#s, -1) == s
end
function String:startswith(s)
	return self:sub(1, #s) == s
end
