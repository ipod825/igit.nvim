require('igit.std_extension')
local List = require('igit.ds.List')
local M = {}

function M.setup(options)
    for name in List({'Branch', 'Log', 'Status'}):iter() do
        local Class = require('igit.' .. name)
        M[name:lower()] = Class(options)
    end
end
return M
