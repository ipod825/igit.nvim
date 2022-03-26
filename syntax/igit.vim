if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "igit"

syn match IgitTermConceal conceal '\e\[[0-9;]*m'
hi default link IgitTermConceal Conceal
setlocal conceallevel=3
setlocal concealcursor=nvci
setlocal nowrap

exec 'syntax match Igit30 "\e\[33m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit31 "\e\[31m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit32 "\e\[32m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit33 "\e\[33m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit34 "\e\[34m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit35 "\e\[35m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit36 "\e\[36m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit37 "\e\[37m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'hi Igit30 ctermfg=30 guifg=#000000'
exec 'hi Igit31 ctermfg=31 guifg=#cd0000'
exec 'hi Igit32 ctermfg=32 guifg=#00cd00'
exec 'hi Igit33 ctermfg=33 guifg=#cdcd00'
exec 'hi Igit34 ctermfg=34 guifg=#000080'
exec 'hi Igit35 ctermfg=35 guifg=#800080'
exec 'hi Igit36 ctermfg=36 guifg=#008080'
exec 'hi Igit37 ctermfg=37 guifg=#808080'

exec 'syntax match Igit30d "\e\[1;33m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit31d "\e\[1;31m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit32d "\e\[1;32m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit33d "\e\[1;33m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit34d "\e\[1;34m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit35d "\e\[1;35m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit36d "\e\[1;36m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'syntax match Igit37d "\e\[1;37m[^\e]*\e\[m"  contains=IgitTermConceal'
exec 'hi Igit30d ctermfg=30 guifg=#000000 gui=bold'
exec 'hi Igit31d ctermfg=31 guifg=#ff0000 gui=bold'
exec 'hi Igit32d ctermfg=32 guifg=#00ff00 gui=bold'
exec 'hi Igit33d ctermfg=33 guifg=#ffff00 gui=bold'
exec 'hi Igit34d ctermfg=34 guifg=#5c5cff gui=bold'
exec 'hi Igit35d ctermfg=35 guifg=#ff00ff gui=bold'
exec 'hi Igit36d ctermfg=36 guifg=#00ffff gui=bold'
exec 'hi Igit37d ctermfg=37 guifg=#ffffff gui=bold'
