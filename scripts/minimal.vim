set rtp +=.
exec 'set rtp +='..getcwd()..'/../plenary.nvim/'
exec 'set rtp +='..getcwd()..'/../libp.nvim/'

runtime! plugin/plenary.vim

set noswapfile
set nobackup
