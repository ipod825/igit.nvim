if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "ivcs"
setlocal conceallevel=3
setlocal concealcursor=nvci
setlocal nowrap

syn match ansiConceal contained conceal "\e\[\(\d*;\)*\d*m\|\e\[K"
hi def link ansiConceal	Ignore

syn region ansiNone		start="\e\[[01;]m"           skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiNone		start="\e\[m"                skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiNone		start="\e\[\%(0;\)\=39;49m"  skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiNone		start="\e\[\%(0;\)\=49;39m"  skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiNone		start="\e\[\%(0;\)\=39m"     skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiNone		start="\e\[\%(0;\)\=49m"     skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiNone		start="\e\[\%(0;\)\=22m"     skip='\e\[K' end="\ze\e\[" contains=ansiConceal
	
syn region ansiBlack		start="\e\[;\=0\{0,2};\=30m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiRed		start="\e\[;\=0\{0,2};\=31m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiGreen		start="\e\[;\=0\{0,2};\=32m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiYellow		start="\e\[;\=0\{0,2};\=33m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiBlue		start="\e\[;\=0\{0,2};\=34m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiMagenta	        start="\e\[;\=0\{0,2};\=35m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiCyan		start="\e\[;\=0\{0,2};\=36m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiWhite		start="\e\[;\=0\{0,2};\=37m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiGray		start="\e\[;\=0\{0,2};\=90m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal

syn region ansiRed		start="\e\[;\=0\{0,2};\=91m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiGreen		start="\e\[;\=0\{0,2};\=92m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiYellow		start="\e\[;\=0\{0,2};\=93m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiBlue		start="\e\[;\=0\{0,2};\=94m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiMagenta	        start="\e\[;\=0\{0,2};\=95m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiCyan		start="\e\[;\=0\{0,2};\=96m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal
syn region ansiWhite		start="\e\[;\=0\{0,2};\=97m" skip='\e\[K' end="\ze\e\[" contains=ansiConceal


syntax match ansiBoldBlack   "\e\[1;33m[^\e]*\e\[m" contains=ansiConceal
syntax match ansiBoldRed     "\e\[1;31m[^\e]*\e\[m" contains=ansiConceal
syntax match ansiBoldGreen   "\e\[1;32m[^\e]*\e\[m" contains=ansiConceal
syntax match ansiBoldYellow  "\e\[1;33m[^\e]*\e\[m" contains=ansiConceal
syntax match ansiBoldBlue    "\e\[1;34m[^\e]*\e\[m" contains=ansiConceal
syntax match ansiBoldMagenta "\e\[1;35m[^\e]*\e\[m" contains=ansiConceal
syntax match ansiBoldCyan    "\e\[1;36m[^\e]*\e\[m" contains=ansiConceal
syntax match ansiBoldWhite   "\e\[1;37m[^\e]*\e\[m" contains=ansiConceal

hi ansiNone	cterm=NONE gui=NONE

hi ansiBlack   ctermfg=black   guifg=#000000
hi ansiRed     ctermfg=red     guifg=#cd0000
hi ansiGreen   ctermfg=green   guifg=#00cd00
hi ansiYellow  ctermfg=yellow  guifg=#cdcd00
hi ansiBlue    ctermfg=blue    guifg=#000080
hi ansiMagenta ctermfg=magenta guifg=#800080
hi ansiCyan    ctermfg=cyan    guifg=#008080
hi ansiWhite   ctermfg=white   guifg=#808080

hi ansiBoldBlack   ctermfg=black   guifg=#000000 gui=bold
hi ansiBoldRed     ctermfg=red     guifg=#ff0000 gui=bold
hi ansiBoldGreen   ctermfg=green   guifg=#00ff00 gui=bold
hi ansiBoldYellow  ctermfg=yellow  guifg=#ffff00 gui=bold
hi ansiBoldBlue    ctermfg=blue    guifg=#5c5cff gui=bold
hi ansiBoldMagenta ctermfg=magenta guifg=#ff00ff gui=bold
hi ansiBoldCyan    ctermfg=cyan    guifg=#00ffff gui=bold
hi ansiBoldWhite   ctermfg=white   guifg=#ffffff gui=bold
