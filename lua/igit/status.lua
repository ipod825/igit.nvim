local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')
local utils = require('igit.utils')

function M.setup(options)
    M.options = M.options or
                    {
            mapping = {['H'] = M.stage_change, ['L'] = M.unstage_change},
            args = {'-s'}
        }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.stage_change()
    local status = git.status_porcelain()
    local line = M.parse_line()
    if status[line.filepath] then
        utils.jobstart(git.add(line.filepath),
                       {post_exit = function() Vbuffer.current():reload() end})
        vim.cmd('normal! j')
    end
end

function M.unstage_change()
    local status = git.status_porcelain()
    local line = M.parse_line()
    if status[line.filepath] then
        utils.jobstart(git.restore('--staged', line.filepath),
                       {post_exit = function() Vbuffer.current():reload() end})
        vim.cmd('normal! j')
    end
end

function M.parse_line()
    local res = {}
    local line = vim.fn.getline('.')
    res.filepath = line:find_str('[^%s]+%s+(.+)$')
    return res
end

function M.open()
    local git_root = git.find_root()

    if git_root then
        Vbuffer.get_or_new({
            vcs_root = git_root,
            filetype = 'status',
            mappings = M.options.mapping,
            reload_fn = function() return git.status(M.options.args) end

        })
    end
end

return M
