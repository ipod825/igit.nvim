local global = require("ivcs.libp.global")("libp")
global.logger = global.logger or require("ivcs.libp.debug.logger")()

return global.logger
