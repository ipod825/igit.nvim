local M = require("igit.libp.datatype.Class"):EXTEND()

function M:NEW()
	local mt = { data = {}, key_arr = {} }
	mt.__index = function(_, key)
		return mt.data[key]
	end
	mt.__newindex = function(_, key, value)
		if value then
			if not mt.data[key] then
				table.insert(mt.key_arr, key)
			end
		else
			if mt.data[key] then
				local new_key_arr = {}
				for _, ori_key in ipairs(mt.key_arr) do
					if ori_key ~= key then
						table.insert(new_key_arr, ori_key)
					end
				end
				mt.key_arr = new_key_arr
			end
		end
		mt.data[key] = value
	end
	local obj = setmetatable({}, mt)
	return obj
end

function M.pairs(d)
	local mt = getmetatable(d)
	assert(mt.key_arr)

	return coroutine.wrap(function()
		for _, key in ipairs(mt.key_arr) do
			coroutine.yield(key, mt.data[key])
		end
	end)
end

function M.keys(d)
	local mt = getmetatable(d)
	assert(mt.key_arr)

	return coroutine.wrap(function()
		for _, key in ipairs(mt.key_arr) do
			coroutine.yield(key)
		end
	end)
end

function M.values(d)
	local mt = getmetatable(d)
	assert(mt.key_arr)

	return coroutine.wrap(function()
		for _, key in ipairs(mt.key_arr) do
			coroutine.yield(mt.data[key])
		end
	end)
end

function M.data(d)
	local mt = getmetatable(d)
	assert(mt.data)
	return mt.data
end

return M
