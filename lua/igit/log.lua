local global = require('igit.libp.global')('igit')

global.logger = global.logger or require('igit.libp.debug.logger')()

return global.logger
