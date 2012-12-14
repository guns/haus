""" Autocommands

augroup GUNS
    autocmd!

    " From vimrc_example.vim: {{{1
    " When editing a file, always jump to the last known cursor position.  Don't
    " do it when the position is invalid or when inside an event handler (happens
    " when dropping a file on gvim).
    " Also don't do it when the mark is in the first line, that is the default
    " position when opening a file.
    autocmd BufReadPost *
        \ if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif

    " :help ft-syntax-omni {{{1
    if has("autocmd") && exists("+omnifunc")
        autocmd Filetype *
            \ if &omnifunc == "" | setlocal omnifunc=syntaxcomplete#Complete | endif
    endif

    " Open the quickfix window if `quickfixcmd!` returns with errors {{{1
    autocmd QuickFixCmdPost *
        \ if !empty(filter(getqflist(), 'get(v:val, "bufnr")')) | cwindow | end

    " Vimscript {{{1
    autocmd FileType help
        \ setlocal iskeyword+=-
    autocmd BufRead /tmp/verbose.vim
        \ silent! :%s/\V^I/	/g

    " Diff {{{1
    autocmd FileType diff
        \ setlocal foldmethod=expr foldexpr=DiffFoldExpr(v:lnum) |
        \ SetWhitespace 8

    " gitcommit {{{1
    autocmd FileType gitcommit
        \ setlocal iskeyword+=- foldmethod=expr foldexpr=DiffFoldExpr(v:lnum) |
        \ SetTextwidth 72 |
        \ SetAutowrap 1

    " Shell {{{1
    autocmd BufRead,BufNewFile *profile,rc.conf,PKGBUILD
        \ setlocal filetype=sh
    autocmd FileType sh
        \ setlocal iskeyword+=- foldmethod=expr foldexpr=ShellFoldExpr(v:lnum)

    " Lisp {{{1
    autocmd Filetype lisp,scheme,clojure
        \ LispBufferSetup

    " Ruby {{{1
    autocmd BufRead,BufNewFile *irbrc,*pryrc,config.ru,Gemfile,*Rakefile
        \ setlocal filetype=ruby
    autocmd BufRead,BufNewFile *Rakefile
        \ setlocal foldmethod=expr foldexpr=RakefileFoldExpr(v:lnum)
    autocmd FileType ruby,eruby
        \ setlocal makeprg=rake iskeyword+=? iskeyword+=! |
        \ execute 'noremap  <buffer> <Leader>R     :<C-u>RunCurrentMiniTestCase<CR>' |
        \ execute 'noremap  <buffer> <Leader><C-b> :B<CR>' |
        \ execute 'noremap! <buffer> <C-l>         <Space>=><Space>' |
        \ SetWhitespace 2 8
    " Metasploit doesn't follow community conventions
    autocmd BufRead,BufNewFile $cdmetasploit/*
        \ setlocal noexpandtab |
        \ SetWhitespace 4 8

    " Python {{{1
    autocmd FileType python
        \ SetWhitespace 4 8

    " PHP {{{1
    autocmd FileType php
        \ SetWhitespace 2 8

    " Haskell {{{1
    autocmd FileType haskell
        \ SetWhitespace 2 8

    " X?HTML/XML {{{1
    autocmd FileType html,xhtml,xml
        \ setlocal synmaxcol=500 iskeyword+=- |
        \ SparkupBufferSetup |
        \ SetWhitespace 2 8

    " HAML/SASS/YAML {{{1
    autocmd FileType haml,sass,yaml
        \ setlocal iskeyword+=- |
        \ SetWhitespace 2 8
    autocmd FileType haml
        \ execute 'noremap  <buffer> <M-CR> i%br<C-\><C-o><C-\><C-n>' |
        \ execute 'noremap! <buffer> <M-CR> %br' |
        \ execute 'noremap! <buffer> <C-l>  <Space>=><Space>'

    " CSS {{{1
    autocmd FileType css
        \ setlocal iskeyword+=- |
        \ SetWhitespace 4 8
    autocmd BufRead,BufNewFile *.less
        \ setlocal filetype=sass |
        \ SetWhitespace 4 8

    " JavaScript {{{1
    autocmd FileType javascript
        \ execute 'let b:jslint_disabled = 1' |
        \ execute 'noremap <buffer> <Leader><C-l> :JSLintToggle<CR>' |
        \ setlocal tags+=./.jstags,.jstags |
        \ SetWhitespace 2 8
    autocmd FileType coffee
        \ SetWhitespace 2 8

    " C {{{1
    autocmd FileType c,c++
        \ setlocal cinoptions=:0

    " Nginx {{{1
    autocmd BufRead,BufNewFile /opt/nginx/etc/*.conf,nginx.conf
        \ setlocal filetype=nginx
    autocmd FileType nginx
        \ setlocal iskeyword-=. iskeyword-=/ iskeyword-=: iskeyword+=- |
        \ SetWhitespace 4 8

    " Ini conf gitconfig {{{1
    autocmd BufRead,BufNewFile *gitconfig
        \ setlocal filetype=gitconfig
    autocmd FileType ini,gitconfig
        \ SetWhitespace 4 8

    " Apache {{{1
    autocmd FileType apache
        \ SetWhitespace 4 8

    " XDefaults {{{1
    autocmd BufRead,BufNewFile *Xdefaults
        \ setlocal filetype=xdefaults

    " UltiSnips snippets {{{1
    autocmd FileType snippets
        \ setlocal noexpandtab iskeyword+=- foldmethod=marker |
        \ SetWhitespace 8

    " Markdown {{{1
    autocmd FileType markdown,rdoc
        \ setlocal iskeyword+=- |
        \ SetTextwidth 72 |
        \ SetWhitespace 4 8

    " Mail {{{1
    autocmd BufRead,BufNewFile editserver-*,vimperator-*,*.mail
        \ setlocal filetype=mail
    autocmd FileType mail
        \ setlocal iskeyword+=- |
        \ SetTextwidth 72 |
        \ SetWhitespace 4 8 |
        \ SetAutowrap 1

    " Mutt {{{1
    autocmd BufRead,BufNewFile ~/.mutt/*rc,/opt/haus/etc/%mutt/muttrc*
        \ setlocal filetype=muttrc

    " Archive browsing {{{1
    autocmd BufReadCmd *.jar,*.xpi,*.pk3
        \ call zip#Browse(expand("<amatch>"))
    autocmd BufReadCmd *.gem
        \ call tar#Browse(expand("<amatch>"))

    " tmux {{{1
    autocmd BufRead,BufNewFile *tmux.conf
        \ setlocal filetype=tmux |
        \ SetWhitespace 4 8

    " screen {{{1
    autocmd BufRead,BufNewFile *screenrc
        \ setlocal filetype=screen

    " http logs {{{1
    autocmd BufRead *access.log*
        \ setlocal filetype=httplog

    " dnsmasq {{{1
    autocmd BufRead,BufNewFile dnsmasq.conf*
        \ setlocal filetype=dnsmasq

    " Applescript (which sucks) {{{1
    autocmd BufRead,BufNewFile *.applescript
        \ setlocal filetype=applescript

    " Readline {{{1
    autocmd BufRead,BufNewFile *inputrc
        \ SetIskeyword! |
        \ setlocal filetype=readline foldmethod=expr foldexpr=ShellFoldExpr(v:lnum)

    " Nethack! {{{1
    autocmd BufRead,BufNewFile *.des
        \ setlocal filetype=nhdes

    " TeX {{{1
    autocmd FileType tex
        \ setlocal iskeyword+=\\ iskeyword+=- |
        \ SetWhitespace 2 8

    " CTags {{{1
    autocmd BufRead,BufNewFile .tags
        \ setlocal filetype=tags

    " Man pages {{{1
    autocmd FileType man
        \ SetIskeyword!

    " Terminfo {{{1
    autocmd BufRead,BufNewFile *.terminfo
        \ setlocal filetype=terminfo

    " vim-orgmode {{{1
    autocmd FileType org
        \ OrgBufferSetup |
        \ SetWhitespace 2 8

    " systemd {{{1
    autocmd BufNewFile,BufRead *.automount,*.mount,*.path,*.service,*.socket,*.swap,*.target,*.timer
        \ set filetype=systemd

    autocmd BufRead,BufNewFile psql.edit.*
        \ setlocal filetype=sql

    augroup ScreenShellEnter "{{{1
        autocmd!
        autocmd User *
            \ ScreenEnterHandler
    augroup END

    augroup ScreenShellExit
        autocmd!
        autocmd User *
            \ ScreenExitHandler
    augroup END

"}}}1
augroup END
