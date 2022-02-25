local M = {}
local branch = require('igit.branch')
local log = require('igit.log')

function M.setup(options)
    branch.setup(options.branch or {})
    log.setup(options.log or {})
end
return M
