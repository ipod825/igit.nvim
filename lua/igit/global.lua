-- Globals is dangerous. Especially when one tries to reload the whole igit by
-- manipulating package.loaded (which is actually very convenient when
-- developing the plugin). In such case, globals are gone and code assuming some
-- valid globals will be broken. Therefore, no module should own its globals,
-- instead, they should store globals in the real global namespace _G, whose
-- extinction is when vim terminates.
_G.__igit = _G.__igit or {}
local M = {}

setmetatable(M, {__index = _G.__igit, __newindex = _G.__igit})

return M
