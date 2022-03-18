local global = require('igit.global')

global.logger = global.logger or require('igit.lib.debug.logger')()

return global.logger
