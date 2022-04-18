local igit = require("igit")
local default_config = require("igit.default_config")

describe("igit", function()
	it("Sets up with default args", function()
		igit.setup()
		for _, module in ipairs({ "log", "branch", "status" }) do
			assert.is_truthy(igit[module])
			for k, v in pairs(default_config[module]) do
				if k ~= "mappings" then
					assert.are.same(igit[module].options[k], v)
				end
			end
		end
	end)

	it("Adds customized command", function()
		igit.setup({ command = "IGitNew" })
		assert.is_truthy(vim.api.nvim_get_commands({}).IGitNew)
	end)
end)
