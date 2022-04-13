local global = require("igit.global")

global.logger = global.logger or require("igit.libp.debug.logger")({ log_file = "igit.log" })

return global.logger
