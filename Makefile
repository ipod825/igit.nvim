test:
	nvim --headless --noplugin -u scripts/minimal.vim -c "PlenaryBustedDirectory lua/ {minimal_init = 'scripts/minimal.vim'}"

lint:
	stylua --check .
