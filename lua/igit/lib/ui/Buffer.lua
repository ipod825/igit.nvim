local M = require 'igit.lib.datatype.Class'()
local global = require('igit.lib.global')('igit')
local functional = require('igit.lib.functional')
local a = require('igit.lib.async.async')
local job = require('igit.lib.job')

function M.open_or_new(opts)
    vim.validate({
        open_cmd = {opts.open_cmd, {'string', 'boolean'}},
        filename = {opts.filename, 'string', true},
        post_open_fn = {opts.post_open_fn, 'function', true}
    })

    local id

    if opts.open_cmd == false then
        id = vim.api.nvim_create_buf(false, true)
        opts.id = id
    else
        vim.cmd(('%s %s'):format(opts.open_cmd, opts.filename))
        if opts.post_open_fn then opts.post_open_fn() end
        id = vim.api.nvim_get_current_buf()
    end

    global.buffers = global.buffers or {}
    if global.buffers[id] == nil then global.buffers[id] = M(opts) end
    return global.buffers[id]
end

function M.get_current_buffer()
    return global.buffers[vim.api.nvim_get_current_buf()]
end

function M:mapfn(mappings)
    if not mappings then return end
    self.mapping_handles = self.mapping_handles or {}
    for mode, mode_mappings in pairs(mappings) do
        vim.validate({
            mode = {mode, 'string'},
            mode_mappings = {mode_mappings, 'table'}
        })
        self.mapping_handles[mode] = self.mapping_handles[mode] or {}
        for key, fn in pairs(mode_mappings) do
            self:add_key_map(mode, key, fn)
        end
    end
end

function M:add_key_map(mode, key, fn)
    vim.validate({
        mode = {mode, 'string'},
        key = {key, 'string'},
        fn = {fn, 'function'}
    })
    local prefix = (mode == 'v') and ':<c-u>' or '<cmd>'
    self.mapping_handles[mode] = self.mapping_handles[mode] or {}
    self.mapping_handles[mode][key] = function()
        if self.is_reloading then return end
        fn()
    end
    vim.api.nvim_buf_set_keymap(self.id, mode, key,
                                ('%slua require("igit.lib.ui.Buffer").execut_mapping("%s", "%s")<cr>'):format(
                                    prefix, mode, key:gsub('^<', '<lt>')), {})
end

function M.execut_mapping(mode, key)
    local b = global.buffers[vim.api.nvim_get_current_buf()]
    key = key:gsub('<lt>', '^<')
    b.mapping_handles[mode][key]()
end

function M:init(opts)
    vim.validate({
        id = {opts.id, 'number', true},
        content = {opts.content, {'function', 'table'}},
        buf_enter_reload = {opts.buf_enter_reload, 'boolean', true},
        mappings = {opts.mappings, 'table', true},
        b = {opts.b, 'table', true},
        bo = {opts.bo, 'table', true}
    })

    self.id = opts.id or vim.api.nvim_get_current_buf()
    self.content = opts.content or functional.nop
    self.mappings = opts.mappings
    self:mapfn(opts.mappings)

    -- For client to store arbitrary lua object.
    local ctx = {}
    self.ctx = setmetatable({}, {__index = ctx, __newindex = ctx})

    self.namespace = vim.api.nvim_create_namespace('')

    for k, v in pairs(opts.b or {}) do
        vim.api.nvim_buf_set_var(self.id, k, v)
    end

    local bo = vim.tbl_extend('force', {
        modifiable = false,
        bufhidden = 'wipe',
        buftype = 'nofile',
        undolevels = -1,
        swapfile = false
    }, opts.bo or {})
    for k, v in pairs(bo) do vim.api.nvim_buf_set_option(self.id, k, v) end
    self.undolevels = bo.undolevels

    vim.api.nvim_create_autocmd('BufDelete', {
        buffer = self.id,
        once = true,
        callback = function() global.buffers[self.id] = nil end
    })

    vim.api.nvim_create_autocmd('BufWinEnter', {
        buffer = self.id,
        once = true,
        callback = function()
            -- setting filetype is put here instead of inside reload because
            -- reload might be called before the window is visible (for e.g.,
            -- buffer created by nvim_create_buf).
            vim.api.nvim_buf_set_option(self.id, 'filetype', opts.bo.filetype)
            self:reload()
        end
    })

    if opts.buf_enter_reload then
        vim.api.nvim_create_autocmd('BufEnter', {
            buffer = self.id,
            callback = function() self:reload() end
        })
    end

    -- todo: This reload might be a waste in some cases. With open_cmd == false,
    -- we reload the buffer on creation here while the Window hasn't be created.
    -- Later, when we defer create the window with nvim_open_win (and focus the
    -- window on creation), BufWinEnter is triggered and reload is called the
    -- second time. Note however, we can't simply do no reload when open_cmd is
    -- false as we might not focus the window with nvim_open_win.
    self:reload()
end

function M:mark(data, max_num_data)
    self.ctx.mark = self.ctx.mark or {}
    if #self.ctx.mark == max_num_data then self.ctx.mark = {} end
    local index = (#self.ctx.mark % max_num_data) + 1
    self.ctx.mark[index] = vim.tbl_extend('error', data,
                                          {linenr = vim.fn.line('.') - 1})

    vim.api.nvim_buf_clear_namespace(self.id, self.namespace, 1, -1)
    for i, d in ipairs(self.ctx.mark) do
        local hi_group
        if i == 1 then
            hi_group = 'RedrawDebugRecompose'
        elseif i == 2 then
            hi_group = 'DiffAdd'
        end
        vim.api.nvim_buf_add_highlight(self.id, self.namespace, hi_group,
                                       d.linenr, 1, -1)
    end
end

function M:save_edit()
    self.ctx.edit.update(self.ctx.edit.ori_items, self.ctx.edit.get_items())
    self.ctx.edit = nil
    vim.bo.buftype = 'nofile'
    vim.bo.modifiable = false
    vim.bo.undolevels = self.undolevels
    self:mapfn(self.mappings)
    self:reload()
end

function M:edit(opts)
    vim.validate({
        get_items = {opts.get_items, 'function'},
        update = {opts.update, 'function'}
    })
    self.ctx.edit =
        vim.tbl_extend('error', opts, {ori_items = opts.get_items()})
    vim.bo.buftype = 'acwrite'
    vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = self.id,
        once = true,
        callback = function() global.buffers[self.id]:save_edit() end
    })
    self:unmapfn(self.mappings)
    vim.bo.undolevels = -1
    vim.bo.modifiable = true
    vim.cmd('substitute/\\e\\[[0-9;]*m//g')
    vim.bo.undolevels = (self.undolevels > 0) and self.undolevels or
                            vim.api.nvim_get_option('undolevels')
end

function M:unmapfn(mappings)
    for mode, mode_mappings in pairs(mappings) do
        vim.validate({
            mode = {mode, 'string'},
            mode_mappings = {mode_mappings, 'table'}
        })
        for key, _ in pairs(mode_mappings) do
            vim.api.nvim_buf_del_keymap(self.id, mode, key)
        end
    end
end

function M:clear()
    vim.api.nvim_buf_set_option(self.id, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.id, 0, -1, false, {})
    vim.api.nvim_buf_set_option(self.id, 'modifiable', false)
end

function M:append(lines)
    vim.api.nvim_buf_set_option(self.id, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.id, -2, -1, false, lines)
    vim.api.nvim_buf_set_option(self.id, 'modifiable', false)
end

function M:save_view()
    if self.id == vim.api.nvim_get_current_buf() then
        self.saved_view = vim.fn.winsaveview()
    end
end

function M:restore_view()
    if self.saved_view and self.id == vim.api.nvim_get_current_buf() then
        vim.fn.winrestview(self.saved_view)
        self.saved_view = nil
    end
end

function M:reload()
    if type(self.content) == 'table' then
        vim.api.nvim_buf_set_option(self.id, 'modifiable', true)
        vim.api.nvim_buf_set_lines(self.id, 0, -1, false, self.content)
        vim.api.nvim_buf_set_option(self.id, 'modifiable', false)
        return
    end

    if self.is_reloading then return end

    a.sync(function()
        self.is_reloading = true
        self:save_view()
        self:clear()

        local count = 1
        local w = vim.api.nvim_get_current_win()
        local ori_st = vim.o.statusline
        a.wait(job.run_async(self.content(), {
            on_stdout = function(lines)
                if not vim.api.nvim_buf_is_valid(self.id) then
                    return true
                end

                self:append(lines)
                -- We only restore view once (note that restore_view destroys
                -- the saved view). This is because that for content that can be
                -- drawn in one shot, reload should finish before any new user
                -- interaction. Restoring the view thus compensate the cursor
                -- move (due to clear). But for content that needs to be drawn
                -- in multiple run, restoring the cursor after every append
                -- just makes user can't do anything.
                self:restore_view()

                if w == vim.api.nvim_get_current_win() then
                    vim.wo.statusline = " Loading " .. ('.'):rep(count)
                    count = count % 6 + 1
                end
            end
        }))

        self.is_reloading = false
        if vim.api.nvim_win_is_valid(w) then
            vim.api.nvim_win_set_option(w, 'statusline', ori_st)
        end
    end)()
end

return M