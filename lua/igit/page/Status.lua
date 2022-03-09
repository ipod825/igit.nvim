local M = require 'igit.page.Page'()
local git = require('igit.git.git')
local job = require('igit.lib.job')
local global = require('igit.global')
local vutils = require('igit.vim_wrapper.vutils')
local Iterator = require('igit.lib.datatype.Iterator')
local Buffer = require('igit.vim_wrapper.Buffer')
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
                ['H'] = self:bind(self.stage_change),
                ['L'] = self:bind(self.unstage_change)
            }
        },
        args = {'-s'}
    }, options)
end

function M:open_file() vim.cmd('edit ' .. self:parse_line().abs_path) end

function M:commit_submit(git_dir, amend, backup_current_branch)
    log.WARN(git_dir, global.pending_commit[git_dir] == nil)
    if global.pending_commit[git_dir] == nil then return end
    global.pending_commit[git_dir] = nil
    local lines = vim.tbl_filter(function(e) return e:sub(1, 1) ~= '#' end,
                                 vim.fn.readfile(git.commit_message_file_path()))
    log.WARN(git.rawcmd('branch --show-current', {git_dir = git_dir}))
    if backup_current_branch then
        local base_branch = job.popen(git.rawcmd('branch --show-current',
                                                 {git_dir = git_dir}))
        local backup_branch =
            ('original_%s_created_by_igit'):format(base_branch)
        job.run(git.rawcmd(('branch %s %s'):format(backup_branch, base_branch)),
                {git_dir = git_dir})
    end
    job.run(git.rawcmd(('commit %s -m "%s"'):format(amend and '--amend' or '',
                                                    table.concat(lines, '\n')),
                       {git_dir = git_dir}))
end

function M:commit(opts)
    opts = opts or {}
    vim.validate({
        amend = {opts.amend, 'boolean', true},
        backup_branch = {opts.backup_branch, 'boolean', true}
    })
    local amend = opts.amend and '--amend' or ''
    local prepare_commit_file_cmd = 'GIT_EDITOR=false git commit ' .. amend
    job.run(prepare_commit_file_cmd, {silent = true})
    local commit_message_file_path = git.commit_message_file_path()
    vim.cmd('edit ' .. commit_message_file_path)
    vim.bo.bufhidden = 'wipe'
    vim.cmd('setlocal bufhidden=wipe')
    global.pending_commit = global.pending_commit or {}
    vim.cmd(
        ('autocmd BufWritePost <buffer> ++once :lua require"igit.global".pending_commit["%s"]=true'):format(
            git.find_root()))
    log.WARN(
        ('autocmd Bufunload <buffer> ++once :lua require"igit".status:commit_submit("%s", %s, %s)'):format(
            git.find_root(), tostring(opts.amend), tostring(opts.backup_branch)))
    vim.cmd(
        ('autocmd Bufunload <buffer> ++once :lua require"igit".status:commit_submit("%s", %s, %s)'):format(
            git.find_root(), tostring(opts.amend), tostring(opts.backup_branch)))
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
        auto_reload = false,
        b = {vcs_root = git.find_root()},
        bo = {buftype = 'nofile', modifiable = false, filetype = ori_filetype},
        reload_cmd_gen_fn = function()
            return git.show(':%s'):format(cline_info.filepath)
        end,
        reload_respect_empty_line = true,
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
        auto_reload = true,
        reload_cmd_gen_fn = function() return git.status(args) end
    })
end

return M
