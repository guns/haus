""" Autocommands

augroup GUNS
	autocmd!

	" From defaults.vim:
	" When editing a file, always jump to the last known cursor position.
	" Don't do it when the position is invalid or when inside an event handler
	" (happens when dropping a file on gvim).
	autocmd BufReadPost *
		\ if line("'\"") >= 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif

	" Remove 'o' from formatoptions because every damn ftplugin sets it
	autocmd FileType *
		\ setlocal formatoptions-=o

	" :help ft-syntax-omni
	if has("autocmd") && exists("+omnifunc")
		autocmd Filetype *
			\ if &omnifunc == "" | setlocal omnifunc=syntaxcomplete#Complete | endif
	endif

	" Quickfix / Location List
	autocmd QuickFixCmdPost *
		\ cwindow | if len(getqflist()) > 0 | wincmd p | endif
	autocmd FileType qf
		\ execute 'noremap <buffer> x :<C-u>call setloclist(0, []) \| lclose \| call setqflist([]) \| cclose<CR>' |
		\ execute 'noremap <buffer> X :<C-u>call setloclist(0, getqflist()) \| topleft lwindow \| call setqflist([]) \| cclose<CR>' |
		\ execute 'noremap <buffer> f :<C-u>call Prompt("Grepqflist ", "\\v")<CR>' |
		\ execute 'noremap <buffer> F :<C-u>call Prompt("Removeqflist ", "\\v")<CR>'

	" Vimscript
	autocmd FileType vim
		\ setlocal foldmethod=expr foldexpr=VimFoldExpr(v:lnum) |
		\ SetWhitespace 4
	autocmd FileType help
		\ setlocal foldmethod=expr foldexpr=VimHelpFoldExpr(v:lnum) iskeyword+=-
	autocmd BufRead /tmp/verbose.vim
		\ silent! :%s/\V^I/	/g
	autocmd BufRead /tmp/profile.vim
		\ silent! :%s/\v[ \t\r]+$//

	" Diff, gitcommit
	autocmd FileType diff,git,gitcommit
		\ setlocal synmaxcol=0 foldmethod=expr foldexpr=DiffFoldExpr(v:lnum)
	autocmd FileType gitcommit
		\ setlocal iskeyword+=- |
		\ SetTextwidth 72 |
		\ SetAutowrap 1

	" Shell
	autocmd BufRead,BufNewFile *profile,rc.conf,PKGBUILD,bash-fc-*,sxhkdrc,bspwmrc
		\ setlocal filetype=sh
	autocmd FileType sh
		\ setlocal expandtab iskeyword+=- foldmethod=expr foldexpr=ShellFoldExpr(v:lnum) |
		\ SetWhitespace 4 8

	" Readline
	autocmd BufRead,BufNewFile *inputrc,*inputrc.d/*
		\ setlocal filetype=readline foldmethod=expr foldexpr=ShellFoldExpr(v:lnum) |
		\ SetWhitespace 4 8

	" Lisp
	autocmd Syntax clojure,timl,scheme,lisp
		\ RainbowParens
	autocmd Filetype lisp,scheme
		\ LispBufferSetup
	autocmd FileType timl
		\ TimLBufferSetup
	autocmd BufRead *.clj
		\ try | silent! Require | catch /^Fireplace/ | endtry
	autocmd Filetype clojure
		\ ClojureBufferSetup

	" Ruby
	autocmd BufRead,BufNewFile *Rakefile,*irbrc,*pryrc,config.ru,Gemfile
		\ setlocal filetype=ruby
	autocmd FileType ruby,eruby
		\ setlocal expandtab makeprg=rake iskeyword+=? iskeyword+=! |
		\ execute 'noremap! <buffer> <C-l> <Space>=><Space>' |
		\ SetWhitespace 2 8

	" X?HTML/XML
	autocmd FileType html,xhtml,xml,gohtmltmpl
		\ setlocal iskeyword+=- |
		\ execute 'noremap  <buffer> <M-CR> i<br><C-\><C-o><C-\><C-n>' |
		\ execute 'noremap! <buffer> <M-CR> <br>'
	autocmd FileType gohtmltmpl
		\ runtime ftplugin/html/sparkup.vim

	" HAML/SASS/YAML
	autocmd BufRead,BufNewFile *.rul
		\ setlocal filetype=yaml
	autocmd FileType haml,sass
		\ setlocal iskeyword+=-
	autocmd FileType haml
		\ execute 'noremap  <buffer> <M-CR> i%br<C-\><C-o><C-\><C-n>' |
		\ execute 'noremap! <buffer> <M-CR> %br' |
		\ execute 'noremap! <buffer> <C-l>  <Space>=><Space>'

	" CSS
	autocmd FileType css
		\ setlocal iskeyword+=-
	autocmd BufRead,BufNewFile *.less
		\ setlocal filetype=scss

	" JavaScript
	autocmd FileType javascript
		\ setlocal tags+=./.jstags,.jstags

	" C
	autocmd FileType c,cpp
		\ setlocal foldmethod=expr foldexpr=CFoldExpr(v:lnum) cinoptions=:0

	" Nginx
	autocmd FileType nginx
		\ setlocal iskeyword-=. iskeyword-=/ iskeyword-=: iskeyword+=-

	" Ini conf gitconfig
	autocmd BufRead,BufNewFile *gitconfig
		\ setlocal filetype=gitconfig
	autocmd BufRead,BufNewFile *.INI,*.toml
		\ setlocal filetype=dosini
	autocmd BufRead,BufNewFile */etc/*hosts,*/etc/ipset.conf
		\ setlocal filetype=conf

	" XDefaults
	autocmd BufRead,BufNewFile *Xdefaults*
		\ setlocal filetype=xdefaults

	" UltiSnips snippets
	autocmd FileType snippets
		\ setlocal iskeyword+=-

	" Markdown
	autocmd FileType markdown,rdoc
		\ setlocal iskeyword+=- foldmethod=expr foldexpr=MarkdownFoldExpr(v:lnum)

	" Mail
	autocmd BufRead,BufNewFile *.mail
		\ setlocal filetype=mail
	autocmd BufRead,BufNewFile vimperator-*
		\ setlocal filetype=markdown |
		\ SetAutowrap 0 |
		\ setlocal wrap synmaxcol=0
	autocmd FileType mail
		\ setlocal iskeyword+=- |
		\ SetTextwidth 72 |
		\ SetAutowrap 1

	" Mutt
	autocmd BufRead,BufNewFile ~/.mutt/*rc,/opt/haus/etc/_mutt/muttrc*
		\ setlocal filetype=muttrc

	" Archive browsing
	autocmd BufReadCmd *.pk3
		\ call zip#Browse(expand("<amatch>"))
	autocmd BufReadCmd *.gem
		\ call tar#Browse(expand("<amatch>"))

	" tmux
	autocmd BufRead,BufNewFile tmux.conf
		\ setlocal filetype=tmux

	" http logs
	autocmd BufRead *access.log*
		\ setlocal filetype=httplog

	" dnsmasq
	autocmd BufRead,BufNewFile *dnsmasq.conf
		\ setlocal filetype=dnsmasq

	" Nethack!
	autocmd BufRead,BufNewFile *.des
		\ setlocal filetype=nhdes

	" TeX
	autocmd FileType tex
		\ setlocal iskeyword+=\\ iskeyword+=- |
		\ SetWhitespace 2 8

	" CTags
	autocmd BufRead,BufNewFile .tags
		\ setlocal filetype=tags

	" Man pages
	autocmd FileType man
		\ SetIskeyword!

	" Terminfo
	autocmd BufRead,BufNewFile *.terminfo
		\ setlocal filetype=terminfo

	" vim-orgmode
	autocmd FileType org
		\ OrgBufferSetup

	" systemd
	autocmd BufNewFile,BufRead */systemd/**/*.{automount,mount,path,service,socket,swap,target,timer}*
		\ setlocal filetype=systemd

	" PostgreSQL
	autocmd BufRead,BufNewFile psql.edit.*
		\ setlocal filetype=sql

	" Rust
	autocmd FileType rust
		\ execute 'noremap! <buffer> <C-l> <Space>=><Space>' |
		\ let b:delimitMate_matchpairs = "(:),[:],{:}" |
		\ SetTextwidth 78 |
		\ SetWhitespace 4

	" Golang
	autocmd FileType go
		\ GoBufferSetup

	" sudo
	autocmd BufRead,BufNewFile *sudoers.d/*
		\ setlocal filetype=sudoers

	" Plugin: Unite.vim
	autocmd FileType unite
		\ silent! syntax clear Tab TrailingWS |
		\ let b:loaded_delimitMate = 1 |
		\ BufReMapall <4-Bslash> <Plug>(unite_all_exit) |
		\ nmap <silent><buffer><expr> <Space> unite#smart_map("\<Plug>(unite_choose_action)", "\<Plug>(unite_toggle_mark_current_candidate)") |
		\ imap <silent><buffer><expr> <Space> unite#smart_map("\<Plug>(unite_choose_action)", "\<Plug>(unite_toggle_mark_current_candidate)")

	" password-store
	autocmd BufRead,BufNewFile /dev/shm/pass.*
		\ setlocal nobackup noswapfile noundofile

augroup END
