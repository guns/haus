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
        \ if line("'\"") > 1 && line("'\"") <= line("$") |
        \   execute "normal! g`\"" |
        \ endif

    " Open the quickfix window if `quickfixcmd!` returns with errors {{{1
    autocmd QuickFixCmdPost *
        \ if !empty(filter(getqflist(), 'get(v:val, "bufnr")')) | cwindow | end

    " Vimscript {{{1
    autocmd FileType vim,help
        \ setlocal iskeyword+=-

    " Diff {{{1
    autocmd FileType diff
        \ setlocal foldmethod=diff foldlevel=0 |
        \ SetWhitespace 8

    " Shell {{{1
    autocmd BufRead,BufNewFile *profile,rc.conf,PKGBUILD
        \ setlocal filetype=sh
    autocmd FileType sh
        \ setlocal iskeyword+=-

    " Lisp {{{1
    autocmd BufRead,BufNewFile *.cljs
        \ setlocal filetype=clojure
    autocmd Filetype lisp,scheme,clojure
        \ LispBufferSetup

    " Ruby {{{1
    autocmd BufRead,BufNewFile *.irbrc,config.ru,Gemfile,*rakefile
        \ setlocal filetype=ruby
    autocmd FileType ruby,eruby
        \ setlocal makeprg=rake iskeyword+=- iskeyword+=? iskeyword+=! |
        \ execute 'noremap <buffer> <Leader><C-b> :B<CR>' |
        \ execute 'noremap <buffer> <Leader>R :<C-u>RunCurrentMiniTestCase<CR>' |
        \ execute 'noremap <buffer> K :silent! ! open http://yard.api/<CR>:redraw!<CR>' |
        \ SetWhitespace 2 8
    " Metasploit doesn't follow community conventions
    autocmd BufRead,BufNewFile $cdmetasploit/*
        \ setlocal noexpandtab |
        \ SetWhitespace 4

    " Python {{{1
    autocmd FileType python
        \ SetWhitespace 4

    " PHP {{{1
    autocmd FileType php
        \ SetWhitespace 2

    " X?HTML/XML {{{1
    autocmd FileType html,xhtml,xml
        \ setlocal matchpairs+=<:> synmaxcol=500 |
        \ SetWhitespace 2

    " HAML/SASS/YAML {{{1
    autocmd FileType haml,sass,yaml
        \ setlocal iskeyword+=- |
        \ SetWhitespace 2
    autocmd FileType haml
        \ execute 'noremap  <buffer> <M-CR> i%br<C-\><C-n><Right>' |
        \ execute 'noremap! <buffer> <M-CR> %br'

    " CSS {{{1
    autocmd FileType css
        \ setlocal iskeyword+=- |
        \ SetWhitespace 4
    autocmd BufRead,BufNewFile *.less
        \ setlocal filetype=sass |
        \ SetWhitespace 4

    " JavaScript {{{1
    autocmd FileType javascript
        \ execute 'let b:jslint_disabled = 1' |
        \ execute 'noremap <buffer> <Leader><C-l> :JSLintToggle<CR>' |
        \ execute 'noremap <buffer> <Leader>!     :JSLintUpdate<CR>' |
        \ SetWhitespace 2
    autocmd FileType coffee
        \ SetWhitespace 2

    " C {{{1
    autocmd FileType c,c++
        \ setlocal cinoptions=:0 |
        \ execute 'noremap! <buffer> <C-l> ->'

    " Nginx {{{1
    autocmd BufRead,BufNewFile /opt/nginx/etc/*.conf,nginx.conf
        \ setlocal filetype=nginx
    autocmd FileType nginx
        \ setlocal iskeyword-=. iskeyword-=/ iskeyword-=: iskeyword+=- |
        \ SetWhitespace 4

    " Ini conf gitconfig {{{1
    autocmd BufRead,BufNewFile *gitconfig
        \ setlocal filetype=gitconfig
    autocmd FileType ini,gitconfig
        \ SetWhitespace 4

    " Apache {{{1
    autocmd FileType apache
        \ SetWhitespace 4

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
        \ SetWhitespace 4

    " Mail {{{1
    autocmd BufRead,BufNewFile editserver-*,*.mail
        \ setlocal filetype=mail
    autocmd FileType mail
        \ setlocal iskeyword+=- |
        \ SetTextwidth 72 |
        \ SetWhitespace 4 |
        \ SetAutowrap 1

    " Archive browsing {{{1
    autocmd BufReadCmd *.jar,*.xpi,*.pk3
        \ call zip#Browse(expand("<amatch>"))
    autocmd BufReadCmd *.gem
        \ call tar#Browse(expand("<amatch>"))

    " git {{{1
    autocmd FileType gitcommit
        \ setlocal iskeyword+=- |
        \ SetTextwidth 72 |
        \ SetAutowrap 1

    " tmux {{{1
    autocmd BufRead,BufNewFile *tmux.conf
        \ setlocal filetype=tmux |
        \ SetWhitespace 4

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
        \ setlocal filetype=readline

    " Nethack! {{{1
    autocmd BufRead,BufNewFile *.des
        \ setlocal filetype=nhdes

    " TeX {{{1
    autocmd FileType tex
        \ setlocal iskeyword+=\\,- |
        \ SetWhitespace 2

    " CTags {{{1
    autocmd BufRead,BufNewFile .tags
        \ setlocal filetype=tags

    " Man pages {{{1
    autocmd FileType man
        \ setlocal iskeyword+=-

    " Terminfo {{{1
    autocmd BufRead,BufNewFile *.terminfo
        \ setlocal filetype=terminfo

    " vim-orgmode {{{1
    autocmd FileType org
        \ OrgBufferSetup |
        \ SetWhitespace 2 8

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
