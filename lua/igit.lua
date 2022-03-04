require('igit.datatype.std_extension')
local M = {}

function M.setup(options)
    M.log = require('igit.page.Log')(options)
    M.branch = require('igit.page.Branch')(options)
    M.status = require('igit.page.Status')(options)
end
return M
