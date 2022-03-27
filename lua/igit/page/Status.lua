local M = require 'igit.page.Page':EXTEND()
local git = require('igit.git')
local job = require('igit.libp.job')
local global = require('igit.global')
local vimfn = require('igit.libp.vimfn')
local Iterator = require('igit.libp.datatype.Iterator')
local Buffer = require('igit.libp.ui.Buffer')
local Window = require('igit.libp.ui.Window')
local DiffWindow = require('igit.libp.ui.DiffWindow')
local FileBuffer = require('igit.libp.ui.FileBuffer')
local Grid = require('igit.libp.ui.Grid')
local path = require('igit.libp.path')
local log = require('igit.log')

function M:init(options)
    self.options = vim.tbl_deep_extend('force', {
        mapping = {
            n = {
                ['H'] = self:BIND(self.stage_change),
                ['L'] = self:BIND(self.unstage_change),
                ['X'] = self:BIND(self.discard_change),
                ['C'] = self:BIND(self.clean_files),
                ['cc'] = self:BIND(self.commit),
                ['ca'] = self:BIND(self.commit, {amend = true}),
                ['cA'] = self:BIND(self.commit,
                                   {amend = true, backup_branch = true}),
                ['dd'] = self:BIND(self.side_diff),
                ['<cr>'] = self:BIND(self.open_file),
                ['t'] = self:BIND(self.open_file, 'tab drop')
            },
            v = {
                ['X'] = self:BIND(self.discard_change),
                ['H'] = self:BIND(self.stage_change),
                ['L'] = self:BIND(self.unstage_change)
            }
        },
        args = {'-s'}
    }, options.status or {})
end

function M:open_file(open_cmd)
    open_cmd = open_cmd or 'edit'
    vim.cmd(('%s %s'):format(open_cmd, self:parse_line().abs_path))
end

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
    if opts.backup_branch then
        local base_branch = job.popen(git.run_from(git_dir).branch(
                                          '--show-current'))
        local backup_branch =
            ('%s_original_created_by_igit'):format(base_branch)
        job.run(git.run_from(git_dir).branch(
                    ('%s %s'):format(backup_branch, base_branch)))
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
    vim.api.nvim_create_autocmd('BufWritePre', {
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
    local paths = Iterator.range(vimfn.visual_rows()):map(
                      function(e)
            local path = self:parse_line(e).filepath
            return status[path] and path or ''
        end):collect()
    self:runasync_and_reload(action(paths))
    return #paths == 1
end

function M:side_diff()
    local cline_info = self:parse_line()

    local grid = Grid()
    local index_buf = Buffer({
        filename = ('igit://HEAD:%s'):format(cline_info.filepath),
        content = function()
            return git.show(':%s'):format(cline_info.filepath)
        end
    })
    local worktree_buf = FileBuffer(cline_info.abs_path)
    vim.filetype.match(cline_info.abs_path, index_buf.id)
    vim.filetype.match(cline_info.abs_path, worktree_buf.id)

    grid:add_row({height = 1}):fill_window(
        Window(Buffer({content = {cline_info.filepath}})))
    grid:add_row({focusable = true}):vfill_windows(
        {
            DiffWindow(index_buf),
            DiffWindow(worktree_buf, {focus_on_open = true})
        }, true)
    -- grid:add_row():vfill_windows({
    --     Window(Buffer({content = {'                 HEAD'}}),
    --            {wo = {winhighlight = 'Normal:Normal'}}),
    --     Window(Buffer({content = {'           Worktree'}},
    --                   {wo = {winhighlight = 'Normal:Normal'}}))
    -- })
    grid:show()
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
    res.abs_path = path.path_join(git.find_root(), res.filepath)
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
