local M = {}
local Job = require("libp.Job")
local Buffer = require("libp.ui.Buffer")

function M.runasync_and_reload(cmd)
    local current_buf = Buffer.get_current_buffer()
    Job({ cmd = cmd }):start()
    current_buf:reload()
end

function M.runasync_all_and_reload(cmds)
    local current_buf = Buffer.get_current_buffer()
    Job.start_all(cmds)
    current_buf:reload()
end

return M
