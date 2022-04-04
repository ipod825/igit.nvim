local M = {}

function M.remove_ansi_escape(str)
	return str:gsub("%c+%[[%d;]*m", "")
end

return M
