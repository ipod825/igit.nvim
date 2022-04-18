local M = require("libp.datatype.Class"):EXTEND()
local util = require("igit.test_util")
local git = util.git
local path = require("libp.path")
local uv = vim.loop
local a = require("plenary.async")
local log = require("igit.log")

function M:init(persist_dir)
	vim.validate({ persist_dir = { persist_dir, "boolean", true } })
	self.persist_dir = persist_dir
	self.files = { "f1", "f2" }
	self.untracked_files = { "nf1", "nf2" }
	self.path1 = { "b1", "b2" }
	self.path2 = { "b3", "b4" }
end

M.current = {}
function M.current:branch()
	return util.check_output(git.branch("--show-current"))[1]
end

function M.current:branches()
	return util.check_output(git.branch())
end

function M.current.staged_files()
	return util.check_output(git.diff("--name-only --cached"))
end

function M.current.worktree_dirty_files()
	return util.check_output(git.diff("--name-only"))
end

function M.current.worktree_untracked_files()
	return util.check_output("git ls-files --others")
end

function M:get_sha(reference)
	return util.check_output(git["rev-parse"](reference))[1]
end

function M:touch_untracked_file(ind)
	util.jobrun(("touch " .. self.untracked_files[ind]))
	return self.untracked_files[ind]
end

function M:commit_message_file_path()
	return ("%s/.git/COMMIT_EDITMSG"):format(self.root)
end

function M:abs_path(fname)
	return path.join(self.root, fname)
end

function M:wait_commit()
	local tx, rx = a.control.channel.oneshot()
	local w = vim.loop.new_fs_event()

	w:start(("%s/.git/objects"):format(self.root), {}, function()
		tx()
		w:stop()
	end)

	a.util.scheduler()
	return function()
		rx()
		a.util.scheduler()
	end
end

function M:refresh()
	if self.root ~= nil then
		util.jobrun(("rm -rf %s"):format(self.root))
		util.jobrun(("cp -r %s_bak %s"):format(self.root, self.root))
		return self.root
	end
	self.root = self:create_dir()
	util.jobrun(("cp -r %s %s_bak"):format(self.root, self.root))
	return self.root
end

function M:create_dir()
	local root
	if self.persist_dir then
		root = "/tmp/igit-test"
	else
		root = vim.fn.tempname()
	end
	util.jobrun(("rm -rf %s %s_bak"):format(root, root))
	local succ = uv.fs_mkdir(root, 448)
	assert(succ, succ)
	local run = function(cmd)
		util.jobrun(cmd, { cwd = root })
	end
	run(("git init --initial-branch %s ."):format(self.path1[1]))
	run(('echo "path 1 file 1 line 1" > %s'):format(self.files[1]))
	run(git.checkout("-b " .. self.path1[1]))
	run(('echo "path 1 file 2 line 1" >> %s'):format(self.files[2]))
	run(git.add("."))
	run(git.commit('-m "path 1 first"'))

	run(git.checkout("-b " .. self.path1[2]))
	run(('echo "line 2" >> %s'):format(self.files[1]))
	run(git.add("."))
	run(git.commit('-m "path 2 second"'))

	run(git.checkout(self.path1[1]))

	run(git.checkout("-b " .. self.path2[1]))
	run(('echo "path 2 file 3 line 1" >> %s'):format(self.files[3]))
	run(git.add("."))
	run(git.commit('-m "path2 first"'))

	run(git.checkout("-b " .. self.path2[2]))
	run(('echo "path 2 file 3 line 2" >> %s'):format(self.files[3]))
	run(git.add("."))
	run(git.commit('-m "path2 second"'))

	run(('echo "path 2 file 3 line 3" >> %s'):format(self.files[3]))
	run(git.add("."))
	run(git.commit('-m "path2 third"'))

	run(git.checkout(self.path1[1]))
	return root
end

return M
