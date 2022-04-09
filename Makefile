test:
	nvim --headless -c "PlenaryBustedDirectory lua"

lint:
	stylua --check .
