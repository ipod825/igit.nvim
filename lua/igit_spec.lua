local igit = require("igit")
local default_config = require("igit.default_config")
local spy = require("luassert.spy")
local match = require("luassert.match")
local itt = require("libp.datatype.itertools")

describe("igit setup", function()
	it("Defaults submodule options to default_config", function()
		igit.setup()
		for module in itt.values({ "log", "branch", "status" }) do
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
		local fake_command = "aaa"
		local git = require("igit.git")
		local s = spy.on(git, "with_default_args")

		-- Parser fails to parse the fake_command, with_default_args was never
		-- called to form the git command to run.
		pcall(vim.cmd, "IGit " .. fake_command)
		assert.spy(s).was_not_called()

		-- Parser succeeds, with_default_args was called to form the git command
		-- to run.
		igit.setup({ git_sub_commands = { "aaa" } })
		vim.cmd("IGit " .. fake_command)
		assert.spy(s).was_called()

		s:revert()
	end)
end)

describe("IGit command", function()
	local function test_mod(modifier)
		it("Honors modifier " .. modifier, function()
			local s = spy.on(igit.log, "open")
			vim.cmd(modifier .. " IGit log")
			local _ = match._
			assert.spy(s).was_called_with(_, _, modifier .. " split")
			s:revert()
		end)
	end
	test_mod("belowright")
	test_mod("topleft")
	test_mod("aboveleft")
	test_mod("vertical")
end)
