local M = {}
require('igit.lib.datatype.std_extension')
local global = require('igit.global')

function M.setup(options)
    global.logger = require('igit.lib.debug.logger')(options)
    M.log = require('igit.page.Log')(options)
    M.branch = require('igit.page.Branch')(options)
    M.status = require('igit.page.Status')(options)
end
return M
