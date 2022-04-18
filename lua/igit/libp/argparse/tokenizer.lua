local M = {}
local log = require("igit.libp.log")

function M.tokenize(str)
	local beg = 1
	local res = {}
	local opening_quote = nil
	local opening_quote_beg = nil

	-- Normalize: no space at begin/end and between flag and equal signs.
	str = str:gsub("^ *", ""):gsub(" *$", ""):gsub("(%-[^ ='\"]+) *= *", "%1=")

	while beg <= #str do
		if opening_quote_beg then
			local _, pend = str:find(("[^\\]%s"):format(opening_quote), beg)
			table.insert(res, str:sub(opening_quote_beg, pend))
			if pend == nil then
				vim.notify("error: Missing quote.")
				return
			end
			beg = str:find("[^ ]", pend + 1) or #str + 1
			opening_quote_beg = nil
			opening_quote = nil
		else
			local pbeg1, pend1 = str:find(" +", beg)
			local pbeg2, pend2, p2 = str:find("[^\\](['\"])", beg - 1)
			if (pbeg1 and pbeg2 and pbeg1 <= pbeg2) or (pbeg1 and not pbeg2) then
				-- Handling space
				table.insert(res, str:sub(beg, pbeg1 - 1))
				beg = pend1 + 1
			elseif pbeg2 then
				-- Handling open quote
				opening_quote_beg = beg
				opening_quote = p2
				beg = pend2 + 1
				if beg > #str then
					vim.notify("error: Missing quote.")
					return
				end
			else
				-- Reaching end. Add the last token
				table.insert(res, str:sub(beg, #str))
				beg = #str + 1
			end
		end
	end
	return res
end

return M
