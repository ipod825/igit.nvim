local M = {
	Buffer = require("igit.libp.ui.Buffer"),
	DiffWindow = require("igit.libp.ui.DiffWindow"),
	TitleWindow = require("igit.libp.ui.TitleWindow"),
	FileBuffer = require("igit.libp.ui.FileBuffer"),
	Grid = require("igit.libp.ui.Grid"),
	InfoBox = require("igit.libp.ui.InfoBox"),
	Menu = require("igit.libp.ui.Menu"),
	Window = require("igit.libp.ui.Window"),
}

function M.center_align_text(content, total_width)
	vim.validate({ content = { content, "table" }, total_width = { total_width, "number" } })
	local num_pads = #content + 1
	local pad_width = total_width
	local content_width = 0
	for _, c in ipairs(content) do
		pad_width = pad_width - #c
		content_width = content_width + #c
	end
	pad_width = math.floor(pad_width / num_pads)
	local offset = math.floor((total_width - pad_width * num_pads - content_width) / 2)

	local res = (" "):rep(offset)
	local pad = (" "):rep(pad_width)
	for _, c in ipairs(content) do
		res = res .. pad .. c
	end
	return res
end

return M
