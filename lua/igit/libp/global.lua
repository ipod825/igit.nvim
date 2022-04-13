-- Globals is dangerous. Especially when one tries to reload the whole plugin by
-- manipulating package.loaded (which is actually very convenient when
-- developing a plugin). In such case, globals are gone and code assuming some
-- valid globals will be broken. Therefore, no module should own its globals,
-- instead, they should store globals in the real global namespace _G, whose
-- extinction is when vim terminates.
local M = {}

setmetatable(M, {
	__call = function(_, name)
		name = "__" .. name
		_G[name] = _G[name] or setmetatable({}, { __index = _G[name], __newindex = _G[name] })
		return _G[name]
	end,
})

return M
