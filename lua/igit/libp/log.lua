local global = require("igit.libp.global")("libp")
global.logger = global.logger or require("igit.libp.debug.logger")({ log_file = "libp.log" })

return global.logger
