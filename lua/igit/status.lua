local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')
local vutils = require('igit.vutils')
local md5 = require('igit.md5')

function M.setup(options)
    M.options = M.options or {
        mapping = {
            ['H'] = M.stage_change,
            ['L'] = M.unstage_change,
            ['X'] = M.discard_change,
            ['cc'] = M.commit,
            ['ca'] = function() M.commit(true) end
        },
        args = {'-s'}
    }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

local non_commented_message_in_commit = function()
    local lines = vim.tbl_filter(function(e) return e:sub(1, 1) ~= '#' end,
                                 vim.fn.readfile(git.commit_message_file_path()))
    return table.concat(lines, '\n')
end

function M.commit_submit(ori_hex, amend)
    local commit_msg = non_commented_message_in_commit()
    if amend then
        vutils.jobsyncstart(git.commit(('--amend --allow-empty -m "%s"'):format(
                                           commit_msg)))
    elseif md5.tohex(commit_msg) ~= ori_hex then
        vutils.jobsyncstart(git.commit(('-m "%s"'):format(commit_msg)))
    end
end

function M.commit(amend)
    local prepare_commit_file_cmd = 'GIT_EDITOR=false git commit ' ..
                                        (amend and '--amend' or '')
    vutils.jobsyncstart(prepare_commit_file_cmd, {on_exit = vutils.nop})
    vim.cmd('tabe ' .. git.commit_message_file_path())
    vim.bo.bufhidden = 'wipe'
    vim.cmd('setlocal bufhidden=wipe')
    local hex = md5.tohex(non_commented_message_in_commit())
    vim.cmd(
        ('autocmd bufunload <buffer> :lua require"igit.status".commit_submit("%s", %s)'):format(
            hex, amend and 'true' or 'false'))
end

function M.change_action(action)
    local status = git.status_porcelain()
    local line = M.parse_line()
    if status[line.filepath] then
        vutils.jobstart(action(line.filepath),
                        {post_exit = function()
            Vbuffer.current():reload()
        end})
        return true
    end
    return false
end

function M.discard_change()
    M.change_action(function(path) return git.restore(path) end)
end

function M.stage_change()
    if M.change_action(function(path) return git.add(path) end) then
        vim.cmd('normal! j')
    end
end

function M.unstage_change()
    if M.change_action(function(path) return git.restore('--staged', path) end) then
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
            auto_reload = true,
            reload_fn = function() return git.status(M.options.args) end

        })
    end
end

return M
