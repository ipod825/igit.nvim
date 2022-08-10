local M = require("igit.page.ReferencePage"):EXTEND()
local git = require("igit.git")
local term_utils = require("libp.utils.term")
local ui = require("libp.ui")
local vimfn = require("libp.utils.vimfn")
local Job = require("libp.Job")
local itt = require("libp.datatype.itertools")

function M:setup(options)
    vim.validate({ options = { options, "t", true } })
    options = options or {}

    self.options = vim.tbl_deep_extend("force", {
        mappings = {
            n = {
                ["s"] = self:BIND(self.show),
            },
            v = {},
        },
    }, options)
    return self
end

function M:show()
    self:SUPER():show(self:parse_line().sha)
end

function M:parse_line(linenr)
    linenr = linenr or "."
    local line = term_utils.remove_ansi_escape(vim.fn.getline(linenr))
    local res = {}
    res.sha = line:find_pattern("([a-f0-9]+)%s")
    return res
end

function M:get_blame_lines(fname)
    local abbrev =
        Job({ cmd = git.config("core.abbrev"), stderr_dump_level = Job.StderrDumpLevel.SILENT }):stdoutputstr()
    abbrev = #abbrev > 0 and tonumber(abbrev) or 10

    local res = {}
    local current = {}
    Job({
        cmd = git.blame("--line-porcelain", fname),
        on_stdout = function(lines)
            for line in itt.values(lines) do
                if line:match("^\t") then
                    table.insert(
                        res,
                        ("%s %s %s %s"):format(
                            current.sha,
                            current.author,
                            vim.fn.strftime("%Y-%m-%d %T", current["author-time"]),
                            current.summary
                        )
                    )
                    current = {}
                else
                    local args = line:split()
                    if #args[1] == 40 then
                        current.sha = args[1]:sub(1, abbrev)
                    elseif args[1] == "summary" then
                        current.summary = line:sub(9, #line)
                    else
                        current[args[1]] = args[2]
                    end
                end
            end
        end,
    }):start()
    return res
end

function M:open(args)
    args = args or self.options.args
    local fname = vim.api.nvim_buf_get_name(0)

    local grid = ui.Grid()

    self:get_blame_lines(fname)

    local blame_win = ui.Window(
        ui.Buffer({
            bo = { filetype = "igit" },
            content = self:get_blame_lines(fname),
            mappings = self.options.mappings,
        }),
        { focusable = true, wo = { wrap = false, cursorline = true, scrolloff = vim.o.lines } }
    )

    grid:add_row({ focusable = true, height = self.options.height }):fill_window(blame_win)
    grid:show()

    local blame_win_config = vim.api.nvim_win_get_config(blame_win.id)

    local file_win = vim.api.nvim_get_current_win()
    local file_buf = vim.api.nvim_get_current_buf()
    local autocmd_group = vim.api.nvim_create_augroup("IGitBlame" .. file_win, {})

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = autocmd_group,
        buffer = file_buf,
        callback = function()
            if not vim.api.nvim_win_is_valid(blame_win.id) then
                vim.api.nvim_del_augroup_by_id(autocmd_group)
                return
            end
            local cursor = vim.api.nvim_win_get_cursor(file_win)
            vim.api.nvim_win_set_cursor(blame_win.id, cursor)
            if cursor[1] <= vimfn.first_visible_line() + self.options.height then
                if type(blame_win_config.row) == "table" then
                    blame_win_config.row = blame_win_config.row[false]
                end
                blame_win_config.row = vim.o.lines - self.options.height - 2
                vim.api.nvim_win_set_config(blame_win.id, blame_win_config)
            elseif cursor[1] >= vimfn.last_visible_line() - self.options.height then
                if type(blame_win_config.row) == "table" then
                    blame_win_config.row = blame_win_config.row[false]
                end
                blame_win_config.row = 0
                vim.api.nvim_win_set_config(blame_win.id, blame_win_config)
            end
        end,
    })
end

return M
