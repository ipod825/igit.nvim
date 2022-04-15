test:
	nvim --headless --noplugin -u scripts/minimal.vim -c "PlenaryBustedDirectory lua/ {minimal_init = 'scripts/minimal.vim'}"
	# nvim --headless -c "PlenaryBustedDirectory lua"

lint:
	stylua --check .
