""" Vim Autocommands

augroup GUNS
    autocmd!

    " From vimrc_example.vim:
    " When editing a file, always jump to the last known cursor position.  Don't
    " do it when the position is invalid or when inside an event handler (happens
    " when dropping a file on gvim).
    " Also don't do it when the mark is in the first line, that is the default
    " position when opening a file.
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   execute "normal! g`\"" |
        \ endif

    " Ensure the quickfix window opens after a `quickfixcmd!`
    autocmd QuickFixCmdPost *
        \ if !empty(getqflist()) | cwindow | end

    " Vimscript
    autocmd FileType help
        \ setlocal iskeyword+=-

    " Diff
    autocmd FileType diff
        \ setlocal foldmethod=diff foldlevel=0 |
        \ SetWhitespace 8

    " Shell
    autocmd BufRead,BufNewFile *profile,rc.conf,PKGBUILD
        \ setlocal filetype=sh
    autocmd FileType sh
        \ setlocal iskeyword+=-

    " Lisp
    autocmd Filetype lisp,scheme,clojure
        \ let b:delimitMate_quotes = '"' |
        \ execute 'noremap <buffer> <C-x>ib :normal ysib(<CR>i' |
        \ execute 'noremap <buffer> <C-x>i( :normal ysib(<CR>i' |
        \ execute 'noremap <buffer> <C-x>i[ :normal ysib[<CR>i' |
        \ execute 'noremap <buffer> <C-x>ic :ToggleClojureFormComment<CR>' |
        \ SetWhitespace 2 8

    " Ruby
    autocmd BufRead,BufNewFile *.irbrc,config.ru,Gemfile,*rakefile
        \ setlocal filetype=ruby
    autocmd FileType ruby,eruby
        \ setlocal makeprg=rake iskeyword+=- iskeyword+=? iskeyword+=! |
        \ execute 'noremap <buffer> <Leader><C-b> :B<CR>' |
        \ SetWhitespace 2 8
    " Metasploit doesn't follow community conventions
    autocmd BufRead,BufNewFile $cdmetasploit/*
        \ setlocal noexpandtab |
        \ SetWhitespace 4

    " Python
    autocmd FileType python
        \ SetWhitespace 4

    " PHP
    autocmd FileType php
        \ SetWhitespace 2

    " X?HTML/XML
    autocmd FileType html,xhtml,xml
        \ setlocal matchpairs+=<:> synmaxcol=500 |
        \ SetWhitespace 2

    " HAML/SASS/YAML
    autocmd FileType haml,sass,yaml
        \ SetWhitespace 2
    autocmd FileType haml
        \ execute 'noremap  <buffer> <M-CR> i%br<Esc><Right>' |
        \ execute 'noremap! <buffer> <M-CR> %br'

    " CSS
    autocmd FileType css
        \ SetWhitespace 4

    " JavaScript
    autocmd FileType javascript
        \ execute 'let b:jslint_disabled = 1' |
        \ execute 'noremap <buffer> <Leader><C-l> :JSLintToggle<CR>' |
        \ execute 'noremap <buffer> <Leader>M :JSLintUpdate<CR>' |
        \ SetWhitespace 2

    " C
    autocmd FileType c
        \ setlocal cinoptions=:0 |
        \ execute 'noremap! <buffer> <C-l> ->'

    " Nginx
    autocmd BufRead,BufNewFile /opt/nginx/etc/*.conf,nginx.conf
        \ setlocal filetype=nginx
    autocmd FileType nginx
        \ setlocal iskeyword-=. iskeyword-=/ iskeyword-=: iskeyword+=- |
        \ SetWhitespace 4

    " Ini conf
    autocmd BufRead,BufNewFile *gitconfig
        \ setlocal filetype=gitconfig
    autocmd FileType ini,gitconfig
        \ SetWhitespace 4

    " Apache conf
    autocmd FileType apache
        \ SetWhitespace 4

    " XDefaults
    autocmd BufRead,BufNewFile *Xdefaults
        \ setlocal filetype=xdefaults

    " UltiSnips snippets
    autocmd FileType snippets
        \ setlocal noexpandtab iskeyword+=- foldmethod=marker |
        \ SetWhitespace 8

    " Markdown
    autocmd FileType markdown,rdoc
        \ setlocal iskeyword+=- |
        \ SetTextwidth 72 |
        \ SetWhitespace 4

    " Mail
    autocmd BufRead,BufNewFile editserver-*,*.mail
        \ setlocal filetype=mail
    autocmd FileType mail
        \ setlocal iskeyword+=- |
        \ SetTextwidth 72 |
        \ SetWhitespace 4 |
        \ SetAutowrap on

    " Archive browsing
    autocmd BufReadCmd *.jar,*.xpi,*.pk3
        \ call zip#Browse(expand("<amatch>"))
    autocmd BufReadCmd *.gem
        \ call tar#Browse(expand("<amatch>"))

    " git
    autocmd FileType gitcommit
        \ setlocal iskeyword+=- |
        \ SetTextwidth 72 |
        \ SetAutowrap on

    " tmux
    autocmd BufRead,BufNewFile *tmux.conf
        \ setlocal filetype=tmux |
        \ SetWhitespace 4

    " screen
    autocmd BufRead,BufNewFile *screenrc
        \ setlocal filetype=screen

    " http logs
    autocmd BufRead *access.log*
        \ setlocal filetype=httplog

    " dnsmasq
    autocmd BufRead,BufNewFile dnsmasq.conf*
        \ setlocal filetype=dnsmasq

    " Applescript (which sucks)
    autocmd BufRead,BufNewFile *.applescript
        \ setlocal filetype=applescript

    " Readline
    autocmd BufRead,BufNewFile *.inputrc
        \ setlocal filetype=readline

    " Nethack!
    autocmd BufRead,BufNewFile *.des
        \ setlocal filetype=nhdes

    " TeX
    autocmd FileType tex
        \ setlocal iskeyword+=\\,- |
        \ SetWhitespace 2

    " CTags
    autocmd BufRead,BufNewFile .tags
        \ setlocal filetype=tags

    " Man pages
    autocmd FileType man
        \ setlocal iskeyword+=-

    " Terminfo
    autocmd BufRead,BufNewFile *.terminfo
        \ setlocal filetype=terminfo

    " vim-orgmode
    autocmd FileType org
        \ setlocal foldlevel=0 |
        \ SetWhitespace 2 8

augroup END

" screen.vim
augroup ScreenShellEnter
    autocmd!
    autocmd User *
        \ silent! execute 'vmap <Leader><Leader> :ScreenSend<CR>' |
        \ silent! execute 'nmap <Leader><Leader> m`vip<Leader><Leader>``' |
        \ silent! execute 'imap <Leader><Leader> <Esc><Leader><Leader><Right>'
augroup END

augroup ScreenShellExit
    autocmd!
    autocmd User *
        \ if !g:ScreenShellActive |
        \   silent! execute 'vunmap <Leader><Leader>' |
        \   silent! execute 'nunmap <Leader><Leader>' |
        \   silent! execute 'iunmap <Leader><Leader>' |
        \ endif
augroup END
