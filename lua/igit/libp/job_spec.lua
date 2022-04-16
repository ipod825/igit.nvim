require("plenary.async").tests.add_to_env()
local Job = require("igit.libp.job")
local a = require("plenary.async")
local Set = require("igit.libp.datatype.Set")
local log = require("igit.libp.log")

describe("start", function()
	local function test_buffer_size(sz)
		describe("on_stdout", function()
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

			a.it("Splits simple stdin" .. sz, function()
				job:send("hello\n")
				job:send("world\n")
				job:shutdown()
				assert.are.same({ "hello", "world" }, results)
			end)

			a.it("Allows empty strings" .. sz, function()
				job:send("hello\n")
				job:send("\n")
				job:send("world\n")
				job:send("\n")
				job:shutdown()
				assert.are.same({ "hello", "", "world", "" }, results)
			end)

			a.it("Splits stdin across newlines" .. sz, function()
				job:send("hello\nwor")
				job:send("ld\n")
				job:shutdown()
				assert.are.same({ "hello", "world" }, results)
			end)

			pending("Splits stdin across newlines with no ending newline" .. sz, function()
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

	a.describe("env", function()
		local results
		local job
		local function run_with_env(env)
			results = {}
			job = Job({
				cmds = { "env" },
				env = env,
				on_stdout = function(lines)
					vim.list_extend(results, lines)
				end,
			})
			job:start()
		end

		a.it("should be possible to set one env variable with an array", function()
			run_with_env({ "A=100" })
			assert.are.same({ "A=100" }, results)
		end)

		a.it("should be possible to set multiple env variables with an array", function()
			run_with_env({ "A=100", "B=test" })
			assert.are.same({ "A=100", "B=test" }, results)
		end)

		a.it("should be possible to set one env variable with a map", function()
			run_with_env({ A = 100 })
			assert.are.same(results, { "A=100" })
		end)

		a.it("should be possible to set one env variable with spaces", function()
			run_with_env({ "A=This is a long env var" })
			assert.are.same({ "A=This is a long env var" }, results)
		end)

		a.it("should be possible to set one env variable with spaces and a map", function()
			run_with_env({ ["A"] = "This is a long env var" })
			assert.are.same({ "A=This is a long env var" }, results)
		end)

		a.it("should be possible to set multiple env variables with a map", function()
			run_with_env({ ["A"] = 100, ["B"] = "test" })
			assert.are.same(Set({ "A=100", "B=test" }), Set(results))
		end)

		a.it("should be possible to set multiple env variables with both, array and map", function()
			run_with_env({ ["A"] = 100, "B=test" })
			assert.are.same(Set({ "A=100", "B=test" }), Set(results))
		end)
	end)
end)

a.describe("check_output", function()
	a.it("Returns  stdout string by default", function()
		assert.are.same("a\nb", Job({ cmds = { "echo", "a\nb" } }):check_output())
	end)
	a.it("Returns list optionally", function()
		assert.are.same({ "a", "b" }, Job({ cmds = { "echo", "a\nb" } }):check_output(true))
	end)
end)
