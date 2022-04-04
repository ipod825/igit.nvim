local global = require("ivcs.global")

global.logger = global.logger or require("ivcs.libp.debug.logger")()

return global.logger
