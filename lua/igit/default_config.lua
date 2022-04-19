return {
	-- The command name igit defined.
	command = "IGit",
	-- A list of git subcommands to be recognized by IGit such that `IGit cmd`
	-- does not error with `unrecognized arguments: cmd`. Note that most default
	-- subcommands such as `commit` or `push` are already recognized. Only
	-- non-built-in subcommands need to be added.
	git_sub_commands = {},
	branch = {
		mappings = {
			n = {},
			v = {},
		},
		-- Command to open the page. If empty "", opens in floatwin.
		open_cmd = "tab drop",
		-- Whether to reload the bufer on BufEnter.
		buf_enter_reload = true,
		-- Default args for that `git branch` command.
		args = { "-v" },
		-- Whether to show up a confirmation menu for rebase.
		confirm_rebase = true,
	},
	log = {
		mappings = {
			n = {},
			v = {},
		},
		-- Command to open the page. If empty "", opens in floatwin.
		open_cmd = "tab drop",
		-- Whether to reload the bufer on BufEnter.
		buf_enter_reload = false,
		-- Default args for that `git log` command.
		args = { "--oneline", "--branches", "--graph", "--decorate=short" },
		-- Whether to show up a confirmation menu for rebase.
		confirm_rebase = true,
	},
	status = {
		mappings = {
			n = {},
			v = {},
		},
		-- Command to open the page. If empty "", opens in floatwin.
		open_cmd = "tab drop",
		-- Whether to reload the bufer on BufEnter.
		buf_enter_reload = true,
		-- Default args for that `git status` command.
		args = { "-s" },
	},
}
