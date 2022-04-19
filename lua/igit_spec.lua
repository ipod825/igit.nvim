local igit = require("igit")
local default_config = require("igit.default_config")

describe("igit setup", function()
	it("Defaults submodule options to default_config", function()
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

	it("Honors command option", function()
		assert.is_falsy(vim.api.nvim_get_commands({}).IGitNew)
		igit.setup({ command = "IGitNew" })
		assert.is_truthy(vim.api.nvim_get_commands({}).IGitNew)
	end)

	it("Honors git_sub_commands options", function()
		local git = require("igit.git")
		local stub = require("luassert.stub")(git, "with_default_args")
		stub.by_default.returns(require("igit.git"))
		local fake_command = "aaa"

		-- Parser fails to parse the fake_command, with_default_args was never
		-- called to form the git command to run.
		vim.cmd("IGit " .. fake_command)
		assert(not stub:called())

		-- Parser succeeds, with_default_args was called to form the git command
		-- to run.
		igit.setup({ git_sub_commands = { "aaa" } })
		vim.cmd("IGit " .. fake_command)
		assert(stub:called())

		stub:revert()
	end)
end)
