set rtp +=.
exec 'set rtp +='..getcwd()..'/../plenary.nvim/'
exec 'set rtp +='..getcwd()..'/../libp.nvim/'

lua << EOF
require("libp").setup()
EOF

runtime! plugin/plenary.vim

set noswapfile
set nobackup
