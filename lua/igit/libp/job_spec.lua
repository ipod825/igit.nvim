require("plenary.async").tests.add_to_env()
local Job = require("igit.libp.job")
local a = require("plenary.async")
local Set = require("igit.libp.datatype.Set")
local log = require("igit.libp.log")

describe("start", function()
	local function test_buffer_size(sz)
		describe("Works with buffer size " .. sz, function()
			local job
			before_each(function()
				job = Job({
					cmds = { "cat" },
					on_stdout_buffer_size = sz,
				})
				a.void(function()
					job:start()
				end)()
			end)

			a.it("Handles simple newline cases", function()
				job:send("hello\n")
				job:send("world\n")
				job:shutdown()
				assert.are.same({ "hello", "world" }, job:stdoutput())
			end)

			a.it("Handles empty line with newline", function()
				job:send("hello\n")
				job:send("\n")
				job:send("world\n")
				job:send("\n")
				job:shutdown()
				assert.are.same({ "hello", "", "world", "" }, job:stdoutput())
			end)

			a.it("Handles partial line", function()
				job:send("hello\nwor")
				job:send("ld\n")
				job:shutdown()
				assert.are.same({ "hello", "world" }, job:stdoutput())
			end)

			a.it("Handles no newline at eof", function()
				job:send("hello\nwor")
				job:send("ld")
				job:shutdown()
				assert.are.same({ "hello", "world" }, job:stdoutput())
			end)
		end)
	end
	test_buffer_size(1)
	test_buffer_size(2)
	test_buffer_size(3)
	test_buffer_size(4)
	test_buffer_size(100)

	local function test_env(env, expect)
		a.it("Works with env " .. vim.inspect(env):gsub("\n", ""), function()
			local job
			job = Job({
				cmds = { "env" },
				env = env,
			})
			job:start()
			assert.are.same(Set(expect), Set(job:stdoutput()))
		end)
	end

	test_env({ "A=100" }, { "A=100" })
	test_env({ "A=100", "B=test" }, { "A=100", "B=test" })
	test_env({ A = 100 }, { "A=100" })
	test_env({ "A=This is a long env var" }, { "A=This is a long env var" })
	test_env({ ["A"] = "This is a long env var" }, { "A=This is a long env var" })
	test_env({ ["A"] = 100, ["B"] = "test" }, { "A=100", "B=test" })
	test_env({ ["A"] = 100, "B=test" }, { "A=100", "B=test" })

	a.it("Respects cwd", function()
		local job
		job = Job({
			cmds = { "pwd" },
			cwd = "/tmp",
		})
		job:start()
		assert.are.same({ "/tmp" }, job:stdoutput())
	end)

	a.it("Takes customized on_stdout", function()
		local results
		local job
		results = {}
		job = Job({
			cmds = { "echo", "a\nb" },
			on_stdout = function(lines)
				vim.list_extend(results, lines)
			end,
		})
		job:start()
		assert.are.same({ "a", "b" }, results)
		assert.are.same(nil, job:stdoutput())
	end)
end)

a.describe("stdoutputstr", function()
	a.it("Returns stdout as a single string", function()
		assert.are.same("a\nb", Job({ cmds = { "echo", "a\nb" } }):stdoutputstr())
	end)
end)
