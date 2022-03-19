local global = require('igit.lib.global')('igit')

global.logger = global.logger or require('igit.lib.debug.logger')()

return global.logger
