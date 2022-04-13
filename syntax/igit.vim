if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "igit"
setlocal conceallevel=3
setlocal concealcursor=nvci
setlocal nowrap

" Libp highlights
hi def link LibpBufferMark1 Search
hi def link LibpBufferMark2 DiffAdd
hi def link LibpTitle Title

" AnsiEscp highlights
syn match AnsiConceal contained conceal "\e\[\(\d*;\)*\d*m\|\e\[K"
hi def link AnsiConceal	Ignore

syn region AnsiNone		start="\e\[[01;]m"           skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiNone		start="\e\[m"                skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiNone		start="\e\[\%(0;\)\=39;49m"  skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiNone		start="\e\[\%(0;\)\=49;39m"  skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiNone		start="\e\[\%(0;\)\=39m"     skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiNone		start="\e\[\%(0;\)\=49m"     skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiNone		start="\e\[\%(0;\)\=22m"     skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
	
syn region AnsiBlack		start="\e\[;\=0\{0,2};\=30m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiRed		start="\e\[;\=0\{0,2};\=31m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiGreen		start="\e\[;\=0\{0,2};\=32m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiYellow		start="\e\[;\=0\{0,2};\=33m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiBlue		start="\e\[;\=0\{0,2};\=34m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiMagenta	        start="\e\[;\=0\{0,2};\=35m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiCyan		start="\e\[;\=0\{0,2};\=36m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiWhite		start="\e\[;\=0\{0,2};\=37m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiGray		start="\e\[;\=0\{0,2};\=90m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal

syn region AnsiRed		start="\e\[;\=0\{0,2};\=91m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiGreen		start="\e\[;\=0\{0,2};\=92m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiYellow		start="\e\[;\=0\{0,2};\=93m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiBlue		start="\e\[;\=0\{0,2};\=94m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiMagenta	        start="\e\[;\=0\{0,2};\=95m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiCyan		start="\e\[;\=0\{0,2};\=96m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal
syn region AnsiWhite		start="\e\[;\=0\{0,2};\=97m" skip='\e\[K' end="\ze\e\[" contains=AnsiConceal


syntax match AnsiBoldBlack   "\e\[1;33m[^\e]*\e\[m" contains=AnsiConceal
syntax match AnsiBoldRed     "\e\[1;31m[^\e]*\e\[m" contains=AnsiConceal
syntax match AnsiBoldGreen   "\e\[1;32m[^\e]*\e\[m" contains=AnsiConceal
syntax match AnsiBoldYellow  "\e\[1;33m[^\e]*\e\[m" contains=AnsiConceal
syntax match AnsiBoldBlue    "\e\[1;34m[^\e]*\e\[m" contains=AnsiConceal
syntax match AnsiBoldMagenta "\e\[1;35m[^\e]*\e\[m" contains=AnsiConceal
syntax match AnsiBoldCyan    "\e\[1;36m[^\e]*\e\[m" contains=AnsiConceal
syntax match AnsiBoldWhite   "\e\[1;37m[^\e]*\e\[m" contains=AnsiConceal

hi AnsiNone	cterm=NONE gui=NONE

hi AnsiBlack   ctermfg=black   guifg=#000000
hi AnsiRed     ctermfg=red     guifg=#cd0000
hi AnsiGreen   ctermfg=green   guifg=#00cd00
hi AnsiYellow  ctermfg=yellow  guifg=#cdcd00
hi AnsiBlue    ctermfg=blue    guifg=#000080
hi AnsiMagenta ctermfg=magenta guifg=#800080
hi AnsiCyan    ctermfg=cyan    guifg=#008080
hi AnsiWhite   ctermfg=white   guifg=#808080

hi AnsiBoldBlack   ctermfg=black   guifg=#000000 gui=bold
hi AnsiBoldRed     ctermfg=red     guifg=#ff0000 gui=bold
hi AnsiBoldGreen   ctermfg=green   guifg=#00ff00 gui=bold
hi AnsiBoldYellow  ctermfg=yellow  guifg=#ffff00 gui=bold
hi AnsiBoldBlue    ctermfg=blue    guifg=#5c5cff gui=bold
hi AnsiBoldMagenta ctermfg=magenta guifg=#ff00ff gui=bold
hi AnsiBoldCyan    ctermfg=cyan    guifg=#00ffff gui=bold
hi AnsiBoldWhite   ctermfg=white   guifg=#ffffff gui=bold
