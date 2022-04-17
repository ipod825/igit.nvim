local M = {}

local size_indxe_name = "_@#$size$#@_"

local SetMt = {}

function SetMt:__eq(that)
	if #self ~= #that then
		return false
	end
	for k in pairs(self) do
		if not that[k] then
			return false
		end
	end
	return true
end

function SetMt:__sub(that)
	local res = M()
	for k in pairs(self) do
		if not M.has(that, k) then
			M.add(res, k)
		end
	end
	return res
end

setmetatable(M, {
	__call = function(_, table)
		table = table or {}
		local obj = setmetatable({ [size_indxe_name] = 0 }, SetMt)
		for _, v in ipairs(table) do
			M.add(obj, v)
		end
		return obj
	end,
})

function M.size(set)
	return set[size_indxe_name]
end

function M._inc(set, s)
	set[size_indxe_name] = set[size_indxe_name] + s
end

function M._dec(set, s)
	set[size_indxe_name] = set[size_indxe_name] - s
end

function M.values(set)
	return coroutine.wrap(function()
		for k, _ in pairs(set) do
			if k ~= size_indxe_name then
				coroutine.yield(k)
			end
		end
	end)
end

function M.has(set, e)
	return set[e] ~= nil
end

function M.add(set, k, v)
	v = v or true
	if set[k] == nil then
		set[k] = v
		M._inc(set, 1)
	end
end

function M.remove(set, k)
	if set[k] ~= nil then
		set[k] = nil
		M._dec(set, 1)
	end
end

function M.intersection(this, that)
	local smaller = (#this < #that) and this or that
	local larger = (#this < #that) and that or this

	local res = {}
	for k in pairs(smaller) do
		if M.has(larger, k) then
			res[#res + 1] = k
		end
	end
	return M(res)
end

return M
