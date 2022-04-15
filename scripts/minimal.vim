set rtp +=.
exec 'set rtp +='..getcwd()..'/../plenary.nvim/'

lua _G.__is_log = true
lua vim.fn.setenv("DEBUG_PLENARY", true)
runtime! plugin/plenary.vim

set noswapfile
set nobackup
