require('igit.std_extension')
local M = {}

function M.setup(options)
    for _, name in ipairs({'Branch', 'Log', 'Status'}) do
        local Class = require('igit.' .. name)
        M[name:lower()] = Class(options)
    end
end
return M
