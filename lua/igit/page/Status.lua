local M = require 'igit.page.Page'()
local git = require('igit.git.git')
local job = require('igit.lib.job')
local global = require('igit.lib.global')('igit')
local vutils = require('igit.vim_wrapper.vutils')
local Iterator = require('igit.lib.datatype.Iterator')
local Buffer = require('igit.lib.ui.Buffer')
local log = require('igit.log')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {
            n = {
                ['H'] = self:bind(self.stage_change),
                ['L'] = self:bind(self.unstage_change),
                ['X'] = self:bind(self.discard_change),
                ['C'] = self:bind(self.clean_files),
                ['cc'] = self:bind(self.commit),
                ['ca'] = self:bind(self.commit, {amend = true}),
                ['cA'] = self:bind(self.commit,
                                   {amend = true, backup_branch = true}),
                ['dd'] = self:bind(self.side_diff),
                ['<cr>'] = self:bind(self.open_file)
            },
            v = {
                ['X'] = self:bind(self.discard_change),
                ['H'] = self:bind(self.stage_change),
                ['L'] = self:bind(self.unstage_change)
            }
        },
        args = {'-s'}
    }, options.status or {})
end

function M:open_file() vim.cmd('edit ' .. self:parse_line().abs_path) end

function M:commit_submit(git_dir, opts)
    opts = opts or {}
    vim.validate({
        amend = {opts.amend, 'boolean', true},
        backup_branch = {opts.backup_branch, 'boolean', true}
    })
    if global.pending_commit[git_dir] == nil then return end
    global.pending_commit[git_dir] = nil

    local lines = vim.tbl_filter(function(e) return e:sub(1, 1) ~= '#' end,
                                 vim.fn.readfile(
                                     git.commit_message_file_path(git_dir)))
    if opts.backup_current_branch then
        local base_branch = job.popen(git.run_from(git_dir).branch(
                                          '--show-current'))
        local backup_branch =
            ('%s_original_created_by_igit'):format(base_branch)
        job.run(git.run_from(git_dir).branch(
                    ('%s %s'):format(backup_branch, base_branch), git_dir))
    end
    job.run(git.run_from(git_dir).commit(
                ('%s -m "%s"'):format(opts.amend and '--amend' or '',
                                      table.concat(lines, '\n')), git_dir))
end

function M:commit(opts)
    opts = opts or {}
    local git_dir = git.find_root()
    local amend = opts.amend and '--amend' or ''
    local prepare_commit_file_cmd = 'GIT_EDITOR=false git commit ' .. amend
    job.run(prepare_commit_file_cmd, {silent = true})
    local commit_message_file_path = git.commit_message_file_path(git_dir)
    vim.cmd('edit ' .. commit_message_file_path)
    vim.bo.bufhidden = 'wipe'
    global.pending_commit = global.pending_commit or {}
    vim.api.nvim_create_autocmd('BufWritePost', {
        buffer = 0,
        once = true,
        callback = function() global.pending_commit[git_dir] = true end
    })
    vim.api.nvim_create_autocmd('Bufunload', {
        buffer = 0,
        once = true,
        callback = function() self:commit_submit(git_dir, opts) end
    })
end

function M:change_action(action)
    local status = git.status_porcelain()
    local paths = Iterator.range(vutils.visual_rows()):map(
                      function(e)
            local path = self:parse_line(e).filepath
            return status[path] and path or ''
        end):collect()
    self:runasync_and_reload(action(paths))
    return #paths == 1
end

function M:side_diff()
    local cline_info = self:parse_line()
    vim.cmd(('split %s'):format(cline_info.abs_path))
    vim.cmd(('resize %d'):format(999))
    vim.cmd('diffthis')
    local ori_filetype = vim.bo.filetype
    local ori_win = vim.api.nvim_get_current_win()

    Buffer.open_or_new({
        open_cmd = 'leftabove vnew',
        filename = ('igit://HEAD:%s'):format(cline_info.filepath),
        buf_enter_reload = false,
        b = {vcs_root = git.find_root()},
        bo = {buftype = 'nofile', modifiable = false, filetype = ori_filetype},
        content = function()
            return git.show(':%s'):format(cline_info.filepath)
        end,
        post_open_fn = function() vim.cmd('diffthis') end
    })
    vim.api.nvim_set_current_win(ori_win)
end

function M:clean_files()
    self:change_action(function(path) return git.clean('-ffd', path) end)
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

function M:open(args)
    args = args or self.options.args
    self:open_or_new_buffer(args, {
        vcs_root = git.find_root(),
        type = 'status',
        mappings = self.options.mapping,
        buf_enter_reload = true,
        content = function() return git.status(args) end
    })
end

return M
