local M = {}

local health_start = vim.fn["health#report_start"]
local health_ok = vim.fn["health#report_ok"]
local health_error = vim.fn["health#report_error"]
local health_warn = vim.fn["health#report_warn"]

function M.check()
    health_start("Installation")
    if vim.fn.executable("git") == 0 then
        health_error("`git` executable not found.", {
            "Install it with your package manager.",
            "Check that your `$PATH` is set correctly.",
        })
    else
        health_ok("`git` executable found.")
    end

    health_start("Api compatibility")
    local apis = { "nvim_create_user_command", "nvim_exec_autocmds", "nvim_create_autocmd" }
    local all_pass = true
    for _, api in ipairs(apis) do
        if not vim.api[api] then
            health_error(api .. " not found.", {
                "Neovim version not supported",
            })
            all_pass = false
        end
    end
    if all_pass then
        health_ok("Current neovim version is supported.")
    end
end

return M
