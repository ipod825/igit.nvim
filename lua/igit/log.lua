local global = require("igit.global")

global.logger = global.logger or require("libp.debug.logger")({ log_file = "igit.log" })

return global.logger
