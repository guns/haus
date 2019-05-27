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
		\ execute 'noremap <buffer> x :<C-u>ClearQuickfix<CR>' |
		\ execute 'noremap <buffer> X :<C-u>call setloclist(winnr("#"), getqflist()) \| call setqflist([]) \| cclose \| topleft lwindow \| wincmd p<CR>' |
		\ execute 'noremap <buffer> f :<C-u>call Prompt("Grepqflist ", "\\v")<CR>' |
		\ execute 'noremap <buffer> F :<C-u>call Prompt("Removeqflist ", "\\v")<CR>' |
		\ execute 'noremap <buffer> S :<C-u>Qfdo s<C-v>\V<C-r>/<C-v><C-v>g<Left><Left>'

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
	autocmd BufRead,BufNewFile *profile,rc.conf,PKGBUILD,bash-fc*,bspwmrc
		\ setlocal filetype=sh
	autocmd BufRead,BufNewFile sxhkdrc
		\ setlocal filetype=sh noexpandtab |
		\ SetWhitespace 8
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
	autocmd FileType ruby
		\ RubyBufferSetup

	" X?HTML/XML
	autocmd FileType html,xhtml,xml,gohtmltmpl,eruby
		\ SetWhitespace 2 |
		\ setlocal iskeyword+=- |
		\ execute 'noremap  <buffer> <M-CR> i<br><C-\><C-o><C-\><C-n>' |
		\ execute 'noremap! <buffer> <M-CR> <br>'
	autocmd FileType gohtmltmpl
		\ runtime ftplugin/html/sparkup.vim

	" HAML/YAML
	autocmd BufRead,BufNewFile *.rul
		\ setlocal filetype=yaml
	autocmd FileType yaml
		\ SetWhitespace 2 |
		\ runtime ftplugin/html/sparkup.vim
	autocmd FileType haml
		\ setlocal iskeyword+=- |
		\ execute 'noremap  <buffer> <M-CR> i%br<C-\><C-o><C-\><C-n>' |
		\ execute 'noremap! <buffer> <M-CR> %br' |
		\ execute 'noremap! <buffer> <C-l>  <Space>=><Space>'

	" CSS
	autocmd FileType sass
		\ SetWhitespace 2 |
		\ setlocal iskeyword+=-
	autocmd FileType css,scss,less
		\ SetWhitespace 4 |
		\ setlocal iskeyword+=-

	" JavaScript
	autocmd FileType javascript
		\ JavaScriptBufferSetup

	" C, C++
	autocmd FileType c,cpp
		\ CBufferSetup

	" Nginx
	autocmd FileType nginx
		\ setlocal iskeyword-=. iskeyword-=/ iskeyword-=: iskeyword+=-

	" Ini conf toml gitconfig
	autocmd BufRead,BufNewFile *gitconfig
		\ setlocal filetype=gitconfig
	autocmd BufRead,BufNewFile *.INI
		\ setlocal filetype=dosini
	autocmd BufRead,BufNewFile */etc/*hosts,ipset.conf,Caddyfile
		\ setlocal filetype=conf
	autocmd BufRead,BufNewFile /etc/wireguard/*.conf
		\ setlocal filetype=toml
	autocmd FileType toml
		\ highlight link tomlTable Special |
		\ highlight link tomlKey Type

	" XDefaults
	autocmd BufRead,BufNewFile *Xdefaults*
		\ setlocal filetype=xdefaults

	" UltiSnips snippets
	autocmd FileType snippets
		\ setlocal iskeyword+=-

	" Markdown
	autocmd FileType markdown,rdoc
		\ setlocal iskeyword+=- foldmethod=expr foldexpr=MarkdownFoldExpr(v:lnum) linebreak breakindent

	" Mail
	autocmd BufRead,BufNewFile *.mail
		\ setlocal filetype=mail
	autocmd FileType mail
		\ MailBufferSetup

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
	autocmd FileType dnsmasq
		\ setlocal expandtab

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
		\ RustBufferSetup

	" Golang
	autocmd FileType go
		\ GoBufferSetup

	" sudo
	autocmd BufRead,BufNewFile *sudoers.d/*
		\ setlocal filetype=sudoers

	" password-store
	autocmd BufRead,BufNewFile /dev/shm/pass.*
		\ setlocal nobackup noswapfile noundofile

	" ASM
	autocmd FileType asm
		\ setlocal smartindent foldmethod=expr foldexpr=AsmFoldExpr(v:lnum) |
		\ execute 'noremap  <buffer> <4-CR> :setlocal virtualedit=all<CR>:call cursor(".", 32)<CR>i; <C-o>:setlocal virtualedit=<CR>' |
		\ execute 'imap     <buffer> <4-CR> <C-\><C-n><4-CR>' |
		\ execute 'inoremap <buffer> <C-l>  <Space>:=<Space>'

	" Elixir
	autocmd FileType elixir
		\ execute 'inoremap <buffer> <Esc>l <Space>=><Space>' |
		\ execute 'inoremap <buffer> <Esc>L <Space>\|><Space>'

augroup END
