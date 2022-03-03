local M = {}
require('igit.std_extension')

function M.setup(options)
    for _, name in ipairs({'branch', 'log', 'status'}) do
        local module = require('igit.' .. name)
        module.setup(options[name] or {})
    end
end
return M
