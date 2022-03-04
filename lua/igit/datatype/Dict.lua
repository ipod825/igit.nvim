local M = require 'igit.datatype.DataStructure'()

function M:items() return pairs(self) end

return M
