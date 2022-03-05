local M = require 'igit.datatype.Class'()
local utils = require 'igit.utils.utils'

function M:init(options)
    self.current_log_level = options.log_level or vim.log.levels.WARN
    self.log_date_format = "%F %H:%M:%S"
    self.format_func = function(arg) return vim.inspect(arg, {newline = ''}) end

    self.logfilename = utils.path_join(vim.fn.stdpath('cache'), 'igit.log')

    vim.fn.mkdir(vim.fn.stdpath('cache'), "p")
    self.logfile = assert(io.open(self.logfilename, "a+"))

    for level, levelnr in pairs(vim.log.levels) do
        self[level] = self:bind(self.log, levelnr)
    end
end

function M:get_filename() return self.logfilename end

function M:set_level(level) self.current_log_level = level end

function M:get_level() return self.current_log_level end

function M:set_format_func(handle)
    assert(handle == vim.inspect or type(handle) == 'function',
           "handle must be a function")
    self.format_func = handle
end

function M:log(level, ...)
    if level < self.current_log_level then return false end
    local argc = select("#", ...)
    if argc == 0 then return true end

    local info = debug.getinfo(2, "Sl")
    local header = string.format("[%s][%s] ...%s:%s", level,
                                 os.date(self.log_date_format), string.sub(
                                     info.short_src, #info.short_src - 15),
                                 info.currentline)
    local parts = {header}
    for i = 1, argc do
        local arg = select(i, ...)
        if arg == nil then
            table.insert(parts, "nil")
        else
            table.insert(parts, self.format_func(arg))
        end
    end
    self.logfile:write(table.concat(parts, '\t'), "\n")
    self.logfile:flush()
end

return M
