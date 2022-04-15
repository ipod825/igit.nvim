return {
	-- The command name igit defined.
	command = "IGit",
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
