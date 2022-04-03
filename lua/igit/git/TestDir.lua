local M = require 'igit.libp.datatype.Class':EXTEND()
local job = require 'igit.libp.job'
local uv = vim.loop

M.git = setmetatable({}, {
    __index = function(_, cmd)
        return function(...)
            return
                ('git --no-pager %s %s'):format(cmd, table.concat({...}, ' '))
        end
    end
})

function M:init()
    self.files = {'f1', 'f2'}
    self.branches = {'b1', 'b2'}
    self.root = self:refresh()
end

function M:refresh()
    if self.root ~= nil then
        vim.fn.system(('rm -rf %s'):format(self.root))
        vim.fn.system(('cp -r %s_bak %s'):format(self.root, self.root))
        -- job.start(('rm -rf %s'):format(self.root))
        -- job.start(('cp -r %s_bak %s'):format(self.root, self.root))
        return self.root
    end
    self.root = self:create_dir()
    vim.fn.system(('cp -r %s %s_bak'):format(self.root, self.root))
    -- job.start(('cp -r %s %s_bak'):format(self.root, self.root))
    return self.root
end

function M:remove_dir(d) job.start(('rm -rf %s %s_bak'):format(d, d)) end

function M:current_branch() return job.popen(self.git.branch('--show-current')) end

function M:create_dir()
    local root = '/tmp/igit-test'
    vim.fn.system(('rm -rf %s %s_bak'):format(root, root))
    -- job.start(('rm -rf %s %s_bak'):format(root, root))
    assert(uv.fs_mkdir(root, 448), "Faile to create directory")
    local run = function(cmd)
        vim.fn.jobwait({vim.fn.jobstart(cmd, {cwd = root})})
    end
    run(('git init --initial-branch %s .'):format(self.branches[1]))
    run(('echo "line 1" > %s'):format(self.files[1]))
    run(self.git.add('.'))
    run(self.git.commit('-m "first"'))
    run(self.git.branch(self.branches[2]))
    return root
end

return M
