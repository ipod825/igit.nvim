local action = require("igit.action")
local functional = require("libp.functional")
local Buffer = require("libp.ui.Buffer")
local IGNORE = Buffer.MultiReloadStrategy.IGNORE
local CANCEL = Buffer.MultiReloadStrategy.CANCEL

return {
    -- The command name igit defined.
    command = "IGit",
    -- A list of git subcommands to be recognized by IGit such that `IGit cmd`
    -- does not error with `unrecognized arguments: cmd`. Note that most default
    -- subcommands such as `commit` or `push` are already recognized. Only
    -- non-built-in subcommands need to be added.
    git_sub_commands = {},
    blame = {
        -- Default height of the blame window.
        height = 5,
    },
    branch = {
        -- Command to open the page. If empty "", opens in floatwin.
        open_cmd = "tab drop",
        -- Whether to reload the bufer on BufEnter.
        buf_enter_reload = true,
        -- Default args for that `git branch` command.
        args = { "-v" },
        -- Whether to show up a confirmation menu for rebase.
        confirm_rebase = true,
        mappings = {
            n = {
                ["<cr>"] = { action.branch.switch, desc = "Switch to the branch under cursor" },
                ["i"] = { action.branch.rename, desc = "Start editing mode" },
                ["m"] = {
                    action.branch.mark,
                    modify_buffer = false,
                    desc = "Mark the current branch for operations",
                },
                ["r"] = {
                    action.branch.rebase_chain,
                    desc = "Rebase the current branch onto the destination commit",
                },
                ["o"] = { action.branch.new_branch, desc = "Start editing mode" },
                ["X"] = {
                    action.branch.force_delete_branch,
                    desc = "Force delete the current branches",
                },
                ["s"] = { action.branch.show, desc = "Show (`git show`) the commit under cursor" },
                ["R"] = { action.branch.reset, desc = "Reset to the commit under cursor" },
            },
            v = {
                ["r"] = {
                    action.branch.rebase_chain,
                    desc = "Rebase the visually selected branches onto the destination commit",
                },
                ["X"] = {
                    action.branch.force_delete_branch,
                    desc = "Force delete the visually selected branches",
                },
            },
        },
    },
    log = {
        -- Command to open the page. If empty "", opens in floatwin.
        open_cmd = "tab drop",
        -- Whether to reload the bufer on BufEnter.
        buf_enter_reload = true,
        -- Default args for that `git log` command.
        args = { "--oneline", "--branches", "--graph", "--decorate=short" },
        -- Whether to show up a confirmation menu for rebase.
        confirm_rebase = true,
        mappings = {
            -- Log pages can contain many lines. We make all mappings
            -- non-blocking by setting multi_reload_strategy.
            n = {
                ["<cr>"] = {
                    action.log.switch,
                    multi_reload_strategy = CANCEL,
                    desc = "Switch to the commit under cursor",
                },
                ["m"] = {
                    action.log.mark,
                    multi_reload_strategy = IGNORE,
                    desc = "Mark the current commit for operations",
                },
                ["s"] = {
                    action.log.show,
                    multi_reload_strategy = IGNORE,
                    desc = "Show (`git show`) the commit under cursor",
                },
                ["r"] = {
                    action.log.rebase_interactive,
                    multi_reload_strategy = CANCEL,
                    desc = "Rebase the commit under cursor onto the destination commit",
                },
                ["R"] = {
                    action.log.reset,
                    multi_reload_strategy = CANCEL,
                    desc = "Reset to the commit under cursor with menu",
                },
            },
            v = {
                ["r"] = {
                    action.log.rebase_chain,
                    multi_reload_strategy = CANCEL,
                    desc = "Rebase the visually selected commit(s) onto the destination commit",
                },
            },
        },
    },
    status = {
        -- Command to open the page. If empty "", opens in floatwin.
        open_cmd = "tab drop",
        -- Whether to reload the bufer on BufEnter.
        buf_enter_reload = true,
        -- Default args for that `git status` command.
        args = { "-s" },
        mappings = {
            n = {
                ["H"] = { action.status.stage_change, desc = "Stage (`git add`) the current file" },
                ["L"] = { action.status.unstage_change, desc = "Unstage (`git restore --staged`) the current file" },
                ["X"] = { action.status.discard_change, desc = "Discard (`git restore`) the current file" },
                ["C"] = { action.status.clean_files, desc = "Clear (`git clean -ffd`) the current untracked file" },
                ["cc"] = { action.status.commit, desc = "Commit change" },
                ["ca"] = { functional.bind(action.status.commit, { amend = true }), desc = "Amend change" },
                ["cA"] = {
                    functional.bind(action.status.commit, { amend = true, backup_branch = true }),
                    desc = "Backup the current with a brandh and then amend change",
                },
                ["dh"] = { action.status.diff_index, desc = "Show diff files between worktree and index" },
                ["dd"] = { action.status.diff_cached, desc = "Show diff files between worktree and stage" },
                ["<cr>"] = { action.status.open_file, desc = "Open the current file" },
                ["t"] = { action.status.open_file, "tab drop", desc = "Open the current file in a new tab" },
            },
            v = {
                ["H"] = { action.status.stage_change, desc = "Stage (`git add`) the visually selected files" },
                ["L"] = {
                    action.status.unstage_change,
                    desc = "Unstage (`git restore --staged`) visually selected files",
                },
                ["X"] = { action.status.discard_change, desc = "Discard (`git restore`) visually selected files" },
                ["C"] = {
                    action.status.clean_files,
                    desc = "Clear (`git clean -ffd`) the visually selected untracked file",
                },
            },
        },
    },
}
