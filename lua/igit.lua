local M = {}
require('igit.std_extension')
local branch = require('igit.branch')
local log = require('igit.log')
local status = require('igit.status')

function M.setup(options)
    for _, name in ipairs({'branch', 'log', 'status'}) do
        local module = require('igit.' .. name)
        module.setup(options[name] or {})
    end
end
return M
