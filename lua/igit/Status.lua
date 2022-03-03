local M = require 'igit.Class'()
local git = require('igit.git')
local job = require('igit.job')
local global = require('igit.global')
local vim_utils = require('igit.vim_utils')
local itertools = require('igit.itertools')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {
            n = {
                ['H'] = function() self:stage_change() end,
                ['L'] = function() self:unstage_change() end,
                ['X'] = function() self:discard_change() end,
                ['cc'] = function() self:commit() end,
                ['ca'] = function() self:commit(true) end,
                ['dd'] = function() self:side_diff() end
            },
            v = {
                ['H'] = function() self:stage_change() end,
                ['L'] = function() self:unstage_change() end
            }
        },
        args = {'-s'}
    }, options)
    self.buffers = require('igit.BufferManager')({type = 'status'})
end

function M:commit_submit(amend)
    if global.pending_commit[git.find_root()] == nil then return end
    global.pending_commit[git.find_root()] = nil
    local lines = vim.tbl_filter(function(e) return e:sub(1, 1) ~= '#' end,
                                 vim.fn.readfile(git.commit_message_file_path()))
    job.run(git.commit(('%s -m "%s"'):format(amend, table.concat(lines, '\n'))))
end

function M:commit(amend)
    local prepare_commit_file_cmd = 'GIT_EDITOR=false git commit ' ..
                                        (amend and '--amend' or '')
    job.run(prepare_commit_file_cmd, {silent = true})
    local commit_message_file_path = git.commit_message_file_path()
    vim.cmd('edit ' .. commit_message_file_path)
    vim.bo.bufhidden = 'wipe'
    vim.cmd('setlocal bufhidden=wipe')
    global.pending_commit = global.pending_commit or {}
    vim.cmd(
        ('autocmd BufWritePre <buffer> ++once :lua require"igit.global".pending_commit["%s"]=true'):format(
            git.find_root()))
    vim.cmd(
        ('autocmd Bufunload <buffer> :lua require"igit".status:commit_submit("%s")'):format(
            amend and '--amend' or ''))
end

function M:change_action(action)
    local status = git.status_porcelain()
    local paths = itertools.range(vim_utils.visual_rows()):map(
                      function(e)
            local path = self:parse_line(e).filepath
            return status[path] and path or ''
        end):collect()

    job.runasync(action(paths),
                 {post_exit = function() self.buffers:current():reload() end})
    return #paths == 1
end

function M:side_diff()
    local cline = self:parse_line()
    vim.cmd(('split %s'):format(cline.abs_path))
    vim.cmd(('resize %d'):format(999))
    vim.cmd('diffthis')
    vim.wo.scrollbind = true
    local ori_filetype = vim.bo.filetype
    local ori_win = vim.api.nvim_get_current_win()

    vim.cmd('vnew')
    job.run(git.show(':%s'):format(cline.filepath), {
        stdout_flush = function(lines)
            vim.api.nvim_buf_set_lines(0, -2, -1, false, lines)
        end
    })
    vim.bo.filetype = ori_filetype
    vim.cmd('diffthis')
    vim.wo.scrollbind = true
    vim.api.nvim_set_current_win(ori_win)
end

function M:discard_change()
    self:change_action(function(path) return git.restore(path) end)
end

function M:stage_change()
    if self:change_action(function(path) return git.add(path) end) then
        vim.cmd('normal! j')
    end
end

function M:unstage_change()
    if self:change_action(
        function(path) return git.restore('--staged', path) end) then
        vim.cmd('normal! j')
    end
end

function M:parse_line(line_nr)
    line_nr = line_nr or '.'
    local res = {}
    local line = vim.fn.getline(line_nr)
    res.filepath = line:find_str('[^%s]+%s+([^%s]+)$')
    res.abs_path = ('%s/%s'):format(git.find_root(), res.filepath)
    return res
end

function M:open()
    self.buffers:open({
        vcs_root = git.find_root(),
        mappings = self.options.mapping,
        auto_reload = true,
        reload_fn = function() return git.status(self.options.args) end
    })
end

return M
