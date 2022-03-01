local M = {}
local git = require('igit.git')
local page = require('igit.page')
local vutils = require('igit.vutils')
local global = require('igit.global')
local itertools = require('igit.itertools')

function M.setup(options)
    M.options = M.options or {
        mapping = {
            n = {
                ['H'] = M.stage_change,
                ['L'] = M.unstage_change,
                ['X'] = M.discard_change,
                ['cc'] = M.commit,
                ['ca'] = function() M.commit(true) end,
                ['dd'] = M.side_diff
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
    local range = vutils.visual_range()
    local paths = vim.tbl_map(function(e)
        local path = M.parse_line(e).filepath
        return status[path] and path or ''
    end, itertools.range(range.row_beg, range.row_end):collect())

    vutils.jobstart(action(paths),
                    {post_exit = function() page.current():reload() end})
    return #paths == 1
end

function M.side_diff()
    local cline = M.parse_line()

    vim.cmd(('split %s'):format(cline.abs_path))
    vim.cmd(('resize %d'):format(999))
    vim.cmd('diffthis')
    vim.wo.scrollbind = true
    local ori_filetype = vim.bo.filetype
    local ori_win = vim.api.nvim_get_current_win()

    vim.cmd('vnew')
    vutils.jobsyncstart(git.show(':%s'):format(cline.filepath), {
        stdout_flush = function(lines)
            vim.api.nvim_buf_set_lines(0, -2, -1, false, lines)
        end
    })
    vim.bo.filetype = ori_filetype
    vim.cmd('diffthis')
    vim.wo.scrollbind = true
    vim.api.nvim_set_current_win(ori_win)
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
    res.abs_path = ('%s/%s'):format(git.find_root(), res.filepath)
    return res
end

function M.open()
    local git_root = git.find_root()

    if git_root then
        page:get_or_new({
            vcs_root = git_root,
            filetype = 'status',
            mappings = M.options.mapping,
            auto_reload = true,
            reload_fn = function() return git.status(M.options.args) end

        })
    end
end

return M
