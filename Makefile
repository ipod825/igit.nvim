test:
	nvim --headless -u scripts/minimal.vim -c "PlenaryBustedDirectory lua"

lint:
	stylua --check .
