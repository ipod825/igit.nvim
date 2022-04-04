local global = require("igit.global")

global.logger = global.logger or require("igit.libp.debug.logger")()

return global.logger
