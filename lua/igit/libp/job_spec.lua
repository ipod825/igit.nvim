require("plenary.async").tests.add_to_env()
local Job = require("igit.libp.job")
local a = require("plenary.async")
local Set = require("igit.libp.datatype.Set")
local log = require("igit.libp.log")

describe("start", function()
	local function test_buffer_size(sz)
		describe("with buffer size " .. sz, function()
			local results
			local job
			before_each(function()
				results = {}
				job = Job({
					cmds = { "cat" },
					stdout_buffer_size = sz,
					on_stdout = function(lines)
						vim.list_extend(results, lines)
					end,
				})
				a.void(function()
					job:start()
				end)()
			end)

			a.it("Splits simple stdin", function()
				job:send("hello\n")
				job:send("world\n")
				job:shutdown()
				assert.are.same({ "hello", "world" }, results)
			end)

			a.it("Allows empty strings", function()
				job:send("hello\n")
				job:send("\n")
				job:send("world\n")
				job:send("\n")
				job:shutdown()
				assert.are.same({ "hello", "", "world", "" }, results)
			end)

			a.it("Splits stdin across newlines", function()
				job:send("hello\nwor")
				job:send("ld\n")
				job:shutdown()
				assert.are.same({ "hello", "world" }, results)
			end)

			a.it("Splits stdin across newlines with no ending newline", function()
				job:send("hello\nwor")
				job:send("ld")
				job:shutdown()
				assert.are.same({ "hello", "world" }, results)
			end)
		end)
	end
	test_buffer_size(1)
	test_buffer_size(2)
	test_buffer_size(3)
	test_buffer_size(4)

	local function test_env(env, expect)
		a.it("with env " .. vim.inspect(env):gsub("\n", ""), function()
			local results
			local job
			results = {}
			job = Job({
				cmds = { "env" },
				env = env,
				on_stdout = function(lines)
					vim.list_extend(results, lines)
				end,
			})
			job:start()
			assert.are.same(Set(expect), Set(results))
		end)
	end

	test_env({ "A=100" }, { "A=100" })
	test_env({ "A=100", "B=test" }, { "A=100", "B=test" })
	test_env({ A = 100 }, { "A=100" })
	test_env({ "A=This is a long env var" }, { "A=This is a long env var" })
	test_env({ ["A"] = "This is a long env var" }, { "A=This is a long env var" })
	test_env({ ["A"] = 100, ["B"] = "test" }, { "A=100", "B=test" })
	test_env({ ["A"] = 100, "B=test" }, { "A=100", "B=test" })
end)

a.describe("check_output", function()
	a.it("Returns  stdout string by default", function()
		assert.are.same("a\nb", Job({ cmds = { "echo", "a\nb" } }):check_output())
	end)
	a.it("Returns list optionally", function()
		assert.are.same({ "a", "b" }, Job({ cmds = { "echo", "a\nb" } }):check_output(true))
	end)
end)
