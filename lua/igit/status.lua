local M = {}
local git = require('igit.git')
local Vbuffer = require('igit.Vbuffer')
local vutils = require('igit.vutils')
local global = require('igit.global')

function M.setup(options)
    M.options = M.options or {
        mapping = {
            n = {
                ['H'] = M.stage_change,
                ['L'] = M.unstage_change,
                ['X'] = M.discard_change,
                ['cc'] = M.commit,
                ['ca'] = function() M.commit(true) end
            },
            v = {['H'] = M.stage_change, ['L'] = M.unstage_change}
        },
        args = {'-s'}
    }
    M.options = vim.tbl_deep_extend('force', M.options, options)
end

function M.commit_submit(amend)
    if global.pending_commit[git.find_root()] == nil then return end
    global.pending_commit[git.find_root()] = nil
    local lines = vim.tbl_filter(function(e) return e:sub(1, 1) ~= '#' end,
                                 vim.fn.readfile(git.commit_message_file_path()))
    vutils.jobsyncstart(git.commit(('%s -m "%s"'):format(amend, table.concat(
                                                             lines, '\n'))))
end

function M.commit(amend)
    local prepare_commit_file_cmd = 'GIT_EDITOR=false git commit ' ..
                                        (amend and '--amend' or '')
    vutils.jobsyncstart(prepare_commit_file_cmd, {on_exit = vutils.nop})
    local commit_message_file_path = git.commit_message_file_path()
    vim.cmd('edit ' .. commit_message_file_path)
    vim.bo.bufhidden = 'wipe'
    vim.cmd('setlocal bufhidden=wipe')
    global.pending_commit = global.pending_commit or {}
    vim.cmd(
        ('autocmd BufWritePre <buffer> ++once :lua require"igit.global".pending_commit["%s"]=true'):format(
            git.find_root()))
    vim.cmd(
        ('autocmd Bufunload <buffer> :lua require"igit.status".commit_submit("%s")'):format(
            amend and '--amend' or ''))
end

local change_action = function(action)
    local status = git.status_porcelain()
    local do_one_line = function(line_nr)
        local line = M.parse_line(line_nr)
        if status[line.filepath] then
            vutils.jobsyncstart(action(line.filepath))
            return true
        end
        return false
    end
    -- local range = vutils.visual_range()
    -- for i in utils.range(range.row_beg, range.row_end) do do_one_line(i) end
    do_one_line('.')
    Vbuffer.current():reload()
end

function M.discard_change()
    change_action(function(path) return git.restore(path) end)
end

function M.stage_change()
    if change_action(function(path) return git.add(path) end) then
        vim.cmd('normal! j')
    end
end

function M.unstage_change()
    if change_action(function(path) return git.restore('--staged', path) end) then
        vim.cmd('normal! j')
    end
end

function M.parse_line(line_nr)
    line_nr = line_nr or '.'
    local res = {}
    local line = vim.fn.getline(line_nr)
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
