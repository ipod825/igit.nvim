if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "ivcs"

syn match IvcsTermConceal conceal '\e\[[0-9;]*m'
hi default link IvcsTermConceal Conceal
setlocal conceallevel=3
setlocal concealcursor=nvci
setlocal nowrap

exec 'syntax match Ivcs30 "\e\[33m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs31 "\e\[31m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs32 "\e\[32m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs33 "\e\[33m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs34 "\e\[34m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs35 "\e\[35m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs36 "\e\[36m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs37 "\e\[37m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'hi Ivcs30 ctermfg=30 guifg=#000000'
exec 'hi Ivcs31 ctermfg=31 guifg=#cd0000'
exec 'hi Ivcs32 ctermfg=32 guifg=#00cd00'
exec 'hi Ivcs33 ctermfg=33 guifg=#cdcd00'
exec 'hi Ivcs34 ctermfg=34 guifg=#000080'
exec 'hi Ivcs35 ctermfg=35 guifg=#800080'
exec 'hi Ivcs36 ctermfg=36 guifg=#008080'
exec 'hi Ivcs37 ctermfg=37 guifg=#808080'

exec 'syntax match Ivcs30d "\e\[1;33m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs31d "\e\[1;31m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs32d "\e\[1;32m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs33d "\e\[1;33m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs34d "\e\[1;34m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs35d "\e\[1;35m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs36d "\e\[1;36m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'syntax match Ivcs37d "\e\[1;37m[^\e]*\e\[m"  contains=IvcsTermConceal'
exec 'hi Ivcs30d ctermfg=30 guifg=#000000 gui=bold'
exec 'hi Ivcs31d ctermfg=31 guifg=#ff0000 gui=bold'
exec 'hi Ivcs32d ctermfg=32 guifg=#00ff00 gui=bold'
exec 'hi Ivcs33d ctermfg=33 guifg=#ffff00 gui=bold'
exec 'hi Ivcs34d ctermfg=34 guifg=#5c5cff gui=bold'
exec 'hi Ivcs35d ctermfg=35 guifg=#ff00ff gui=bold'
exec 'hi Ivcs36d ctermfg=36 guifg=#00ffff gui=bold'
exec 'hi Ivcs37d ctermfg=37 guifg=#ffffff gui=bold'
