""" Library of commands

command! -nargs=+ -complete=command -bar Mapall call <SID>Mapall(<f-args>) " {{{1
function! <SID>Mapall(...)
    execute 'noremap  ' . join(a:000)
    execute 'noremap! ' . a:1 . ' <C-\><C-n>' . join(a:000[1:])
endfunction


command! -nargs=* -bang -bar SetWhitespace call <SID>SetWhitespace('<bang>', <f-args>) "{{{1
function! <SID>SetWhitespace(bang, ...)
    if a:0
        let local = empty(a:bang) ? 'local' : ''
        execute 'set' . local . ' shiftwidth=' . a:1
        execute 'set' . local . ' softtabstop=' . a:1
        execute 'set' . local . ' tabstop=' . (a:0 == 2 ? a:2 : a:1)
    else
        echo 'sw=' . &shiftwidth . ' ts=' . &tabstop . ' sts=' . &softtabstop
    endif
endfunction


command! -nargs=* -bang -bar SetTextwidth call <SID>SetTextwidth('<bang>', <f-args>) "{{{1
function! <SID>SetTextwidth(bang, ...)
    if a:0
        let local = empty(a:bang) ? 'local' : ''
        execute 'set' . local . ' textwidth=' . a:1
        if g:__FEATURES__['par']
            let paropts = a:0 == 2 ? a:2 : 'heq'
            execute 'set' . local . ' formatprg=par\ ' . paropts . '\ ' . a:1
        endif
    else
        echo 'tw=' . &textwidth . ' fp=' . &formatprg
    endif
endfunction


command! -nargs=? -bang -bar SetAutowrap call <SID>SetAutowrap('<bang>', <f-args>) "{{{1
function! <SID>SetAutowrap(bang, ...)
    let status = empty(a:bang) ? (a:0 ? a:1 : -1) : (&formatoptions =~ 'a' ? 0 : 1)

    if status == -1
        echo &formatoptions =~ 'a' ? 'Autowrap is on' : 'Autowrap is off'
    elseif status
        execute 'setlocal formatoptions+=t formatoptions+=a formatoptions+=w'
    else
        execute 'setlocal formatoptions-=t formatoptions-=a formatoptions-=w'
    endif
endfunction


command! -bang -bar SetIskeyword call <SID>SetIskeyword('<bang>') "{{{1
function! <SID>SetIskeyword(bang)
    let nonspaces = '@,1-31,33-127'
    if empty(a:bang)
        set iskeyword?
    elseif &iskeyword != nonspaces
        let b:__iskeyword__ = &iskeyword
        execute 'setlocal iskeyword=' . nonspaces
    else
        execute 'setlocal iskeyword=' . b:__iskeyword__
    endif
endfunction


command! -bang -bar SetDiff call <SID>SetDiff('<bang>') "{{{1
function! <SID>SetDiff(bang)
    if empty(a:bang)
        set diff?
    elseif &diff
        windo execute "if expand(\"%:t\") !=# \"index\" | diffoff | setlocal nowrap | endif"
    else
        windo execute "if expand(\"%:t\") !=# \"index\" | diffthis | endif"
    endif
endfunction


command! -nargs=? -bang -bar SetVerbose call <SID>SetVerbose('<bang>', <f-args>) "{{{1
function! <SID>SetVerbose(bang, ...)
    let enable = a:0 ? a:1 : (exists('g:SetVerbose') ? 0 : 1)

    if empty(a:bang)
        set verbose?
    elseif enable
        let g:SetVerbose = 1
        set verbose=100 verbosefile=/tmp/verbose.vim
        echo '♫ BEGIN VERBOSE MODE ♫'
    else
        echo '♫ END VERBOSE MODE ♫'
        set verbose=0 verbosefile=
        unlet! g:SetVerbose
    endif
endfunction


command! -bar SynStack call <SID>SynStack() "{{{1
function! <SID>SynStack()
    " TextMate style syntax highlighting stack for word under cursor
    " http://vimcasts.org/episodes/creating-colorschemes-for-vim/
    if exists("*synstack")
        echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
    endif
endfunction


command! -nargs=? -bar -complete=file Todo call <SID>Todo(<f-args>) "{{{1
function! <SID>Todo(...)
    let words = ['TODO', 'FIXME', 'NOTE', 'WARNING', 'DEBUG', 'HACK', 'XXX']
    let arg = a:0 ? shellescape(expand(a:1), 1) : '.'

    " Fugitive detects Git repos for us
    if !exists(':Ggrep')
        execute 'silent! Ggrep! -Ew "' . join(words,'|') . '" ' . (a:0 ? arg : shellescape(getcwd(), 1))
    elseif exists(':Ack')
        execute 'silent! Ack! -w "' . join(words,'\|') . '" ' . arg
    else
        execute 'silent! grep! -r -Ew "' . join(words,'\|') . '" ' . arg
    endif

    redraw!
endfunction


command! -bar Ctags call <SID>Ctags() "{{{1
function! <SID>Ctags()
    let cmd = (&filetype == 'javascript') ? 'jsctags.js -f .jstags ' . shellescape(expand('%')) : 'ctags -R'
    execute 'silent! !(' . cmd . '; notify --audio) &>/dev/null &' | redraw! | echo cmd
endfunction


function! ShellFoldExpr(lnum)
    if getline(a:lnum) =~# '\v^\s*\#\#\#\s' && empty(getline(a:lnum - 1))
        return '>1'
    else
        return '='
    endif
endfunction


function! DiffFoldExpr(lnum) "{{{1
    if getline(a:lnum) =~# '\v^diff>'
        return '>1'
    else
        return '='
    endif
endfunction


function! RakefileFoldExpr(lnum) "{{{1
    if getline(a:lnum) =~# '\v^\s*<task>'
        return '>1'
    elseif getline(a:lnum + 1) =~# '\v^\s*<(desc|namespace)>'
        return 's1'
    else
        return '='
    endif
endfunction


function! LispFoldExpr(lnum) "{{{1
    let line = getline(a:lnum)
    if line =~ '\v^\s*;;;\s' && getline(a:lnum - 1) =~ '\v^\s*;;;$' && empty(getline(a:lnum - 2))
        return '>1'
    elseif line =~# '\v.*[\(/]def.*'
        return '>2'
    else
        return '='
    endif
endfunction


command! -bar LispBufferSetup call <SID>LispBufferSetup() "{{{1
function! <SID>LispBufferSetup()
    let b:delimitMate_quotes = '"'
    setlocal iskeyword+='
    SetWhitespace 2 8

    setlocal foldmethod=expr foldexpr=LispFoldExpr(v:lnum)

    nnoremap <buffer> <Leader>C :StartNailgunServer \| silent edit<CR>
    noremap! <buffer> <C-l>      ->
    noremap  <buffer> <4-CR>     A<Space>;<Space>
    noremap! <buffer> <4-CR>     <C-\><C-o>A<Space>;<Space>
    nnoremap <buffer> ==         :normal m`=a(``<CR>
    nnoremap <buffer> =p         :normal m`=ap``<CR>
    nnoremap <buffer> <C-]>      :<C-u>ClojureTagJump.<CR>
    nnoremap <buffer> <C-w><C-]> :<C-u>split \| ClojureTagJump.<CR>

    "
    " VimClojure
    "

    " RECURSIVE map for <Plug> mappings
    nmap <silent> <buffer> K             <Plug>ClojureSourceLookupWord.
    nmap <silent> <buffer> <Leader>Q     <Plug>ClojureCloseResultBuffer.
    nmap <silent> <buffer> <Leader>r     <Plug>ClojureStartLocalRepl.
    nmap <silent> <buffer> <Leader>R     <Plug>ClojureStartRepl.
    nmap <silent> <buffer> <Leader><C-r> <Plug>ClojureRequireFileCurrent.

    " cf. ScreenSetup
    vmap <silent> <buffer> <Leader><Leader> <Plug>ClojureEvalBlock.
    nmap <silent> <buffer> <Leader><Leader> mp:call PareditSelectCurrentForm()<CR><Leader><Leader>`p
    imap <silent> <buffer> <Leader><Leader> <C-\><C-o><C-\><C-n><Leader><Leader>
    nmap <silent> <buffer> <Leader><C-f>    <Plug>ClojureEvalToplevel.
    imap <silent> <buffer> <Leader><C-f>    <C-\><C-o><C-\><C-n><Leader><C-f>

    " Cheatsheet (TODO should be temporary)
    nnoremap <silent> <buffer> <LocalLeader>cs :ClojureCheatSheet!<CR>
    nnoremap <silent> <buffer> <LocalLeader>ci :ClojureCheatSheet<CR>

    " Repl bindings
    if exists('b:vimclojure_repl')
        nmap <silent> <buffer> <Leader>Q  GS,close<CR>
        nmap <silent> <buffer> <Leader>tp GS,toggle-pprint<CR>
    endif

    "
    " Paredit
    "

    " Initialize Paredit, but don't create any mappings
    let g:paredit_mode = 0
    let g:paredit_electric_return = 0
    call PareditInitBuffer()
    let g:paredit_mode = 1

    " Movement
    nnoremap <silent> <buffer> [[ :<C-u>call PareditFindDefunBck()<CR>zz
    nnoremap <silent> <buffer> ]] :<C-u>call PareditFindDefunFwd()<CR>zz
    nnoremap <silent> <buffer> (  :<C-u>call PareditFindOpening(0,0,0)<CR>
    nnoremap <silent> <buffer> )  :<C-u>call PareditFindClosing(0,0,0)<CR>

    " Auto-balancing insertion
    inoremap <silent> <buffer> <expr> ( PareditInsertOpening('(',')')
    inoremap <silent> <buffer> <expr> [ PareditInsertOpening('[',']')
    inoremap <silent> <buffer> <expr> { PareditInsertOpening('{','}')
    inoremap <silent> <buffer> <silent> ) <C-R>=(pumvisible() ? "\<lt>C-Y>" : "")<CR><C-O>:let save_ve=&ve<CR><C-O>:set ve=onemore<CR><C-O>:<C-U>call PareditInsertClosing('(',')')<CR><C-O>:let &ve=save_ve<CR>
    inoremap <silent> <buffer> <silent> ] <C-R>=(pumvisible() ? "\<lt>C-Y>" : "")<CR><C-O>:let save_ve=&ve<CR><C-O>:set ve=onemore<CR><C-O>:<C-U>call PareditInsertClosing('[',']')<CR><C-O>:let &ve=save_ve<CR>
    inoremap <silent> <buffer> <silent> } <C-R>=(pumvisible() ? "\<lt>C-Y>" : "")<CR><C-O>:let save_ve=&ve<CR><C-O>:set ve=onemore<CR><C-O>:<C-U>call PareditInsertClosing('{','}')<CR><C-O>:let &ve=save_ve<CR>
    if g:paredit_electric_return
        inoremap <buffer> <expr> <CR> PareditEnter()
    endif

    " Select next/prev item in list
    nnoremap <silent> <buffer> <Leader>j :<C-u>call PareditSelectListElement(1)<CR>
    vnoremap <silent> <buffer> <Leader>j <C-\><C-n>:<C-u>call PareditSelectListElement(1)<CR>
    nnoremap <silent> <buffer> <Leader>k :<C-u>call PareditSelectListElement(0)<CR>
    vnoremap <silent> <buffer> <Leader>k o<C-\><C-n><Left>:<C-u>call PareditSelectListElement(0)<CR>

    " Insert at beginning, end of form
    nnoremap <silent> <buffer> <Leader>I :<C-u>call PareditFindOpening(0,0,0)<CR>a<Space><Left>
    nnoremap <silent> <buffer> <Leader>l :<C-u>call PareditFindClosing(0,0,0)<CR>i

    " Wrap word/selection, then insert at front/end
    nnoremap <silent> <buffer> <Leader>w :<C-u>call PareditWrap('(',')')<CR>%i
    vnoremap <silent> <buffer> <Leader>w :<C-u>call PareditWrapSelection('(',')')<CR>i
    nnoremap <silent> <buffer> <Leader>W :<C-u>call PareditWrap('(',')')<CR>a<Space><Left>
    vnoremap <silent> <buffer> <Leader>W :<C-u>call PareditWrapSelection('(',')')<CR>%a<Space><Left>
    nnoremap <silent> <buffer> <Leader>( :<C-u>call PareditWrap('(',')')<CR>a<Space><Left>
    nnoremap <silent> <buffer> <Leader>) :<C-u>call PareditWrap('(',')')<CR>%i
    vnoremap <silent> <buffer> <Leader>( :<C-u>call PareditWrapSelection('(',')')<CR>%a<Space><Left>
    vnoremap <silent> <buffer> <Leader>) :<C-u>call PareditWrapSelection('(',')')<CR>i
    nnoremap <silent> <buffer> <Leader>[ :<C-u>call PareditWrap('[',']')<CR>a<Space><Left>
    nnoremap <silent> <buffer> <Leader>] :<C-u>call PareditWrap('[',']')<CR>%i
    vnoremap <silent> <buffer> <Leader>[ :<C-u>call PareditWrapSelection('[',']')<CR>%a<Space><Left>
    vnoremap <silent> <buffer> <Leader>] :<C-u>call PareditWrapSelection('[',']')<CR>i
    nnoremap <silent> <buffer> <Leader>{ :<C-u>call PareditWrap('{','}')<CR>a<Space><Left>
    nnoremap <silent> <buffer> <Leader>} :<C-u>call PareditWrap('{','}')<CR>%i
    vnoremap <silent> <buffer> <Leader>{ :<C-u>call PareditWrapSelection('{','}')<CR>%a<Space><Left>
    vnoremap <silent> <buffer> <Leader>} :<C-u>call PareditWrapSelection('{','}')<CR>i

    " Wrap form/selection, then insert in front
    nnoremap <silent> <buffer> <Leader>i :<C-u>call PareditFindClosing(0,0,0) \| call PareditWrap('(',')')<CR>a<Space><Left>
    vnoremap <silent> <buffer> <Leader>i :<C-u>call PareditWrapSelection('(',')')<CR>%a<Space><Left>

    " paredit-raise-sexp
    nnoremap <silent> <buffer> <Leader>o :<C-u>call PareditRaiseSexp()<CR>

    " Toggle Clojure (comment)
    nnoremap <silent> <buffer> <Leader>cc :<C-u>call PareditToggleClojureComment()<CR>
endfunction


command! -nargs=? -bar StartNailgunServer call <SID>StartNailgunServer(<args>) "{{{1
function! <SID>StartNailgunServer(...)
    if g:vimclojure#WantNailgun
        echo 'Already ' . (g:NailgunServerStarted ? "started" : "attached to") . ' Nailgun server!'
        return
    endif
    let g:vimclojure#WantNailgun = 1
    let g:NailgunServerStarted = 0
    let g:vimclojure#NailgunPort = a:0 ? a:1 : 2113

    call system('nc -z 127.0.0.1 ' . g:vimclojure#NailgunPort)
    if v:shell_error
        silent! execute '! clojure --lein "trampoline vimclojure :port ' . g:vimclojure#NailgunPort . '" &>/dev/null &'
        silent! execute '! until nc -z 127.0.0.1 ' . g:vimclojure#NailgunPort . ' &>/dev/null; do echo -n .; sleep 1; done'
        let g:NailgunServerStarted = 1
    endif

    augroup NailgunServer
        autocmd!
        autocmd VimLeave *
            \ StopNailgunServer
    augroup END

    if exists('b:vimclojure_loaded')
        unlet b:vimclojure_loaded
    endif
    call vimclojure#InitBuffer()
    redraw!

    echo (g:NailgunServerStarted ? 'Started' : 'Attached to') . ' Nailgun server'
endfunction


command! -bar StopNailgunServer call <SID>StopNailgunServer() "{{{1
function! <SID>StopNailgunServer()
    let g:vimclojure#WantNailgun = 0

    if exists('g:NailgunServerStarted') && g:NailgunServerStarted
        silent! execute '!' . g:vimclojure#NailgunClient . ' ng-stop --nailgun-port ' . g:vimclojure#NailgunPort . ' &>/dev/null &' | redraw!
        echo 'Killing Nailgun server'
        let g:NailgunServerStarted = 0
    else
        echo 'Unloading Nailgun server'
    endif

    augroup NailgunServer
        autocmd!
    augroup END
endfunction


command! -bar -bang ClojureCheatSheet call <SID>ClojureCheatSheet('<bang>') " {{{1
function! <SID>ClojureCheatSheet(bang)
    if exists('g:vimclojure#WantNailgun') && g:vimclojure#WantNailgun
        if a:bang ==# '!'
            let clj = "(vimclojure.util/print-cheat-sheet!)"
        else
            let clj = "(vimclojure.util/print-cheat-sheet! #\"" . input('Namespace filter regex: ') . "\")"
        endif
        call vimclojure#Eval(clj)
        normal yG
        wincmd q | vsplit | wincmd L | execute 'Scratch' | setlocal filetype=clojure
        normal gg"_dGP
    endif
endfunction

command! -nargs=? -complete=shellcmd -bar Screen call <SID>Screen(<q-args>) "{{{1
function! <SID>Screen(command)
    let map = {
        \ 'ruby'       : 'script/rails console || pry || irb',
        \ 'clojure'    : 'clojure --lein repl',
        \ 'python'     : 'python',
        \ 'scheme'     : 'scheme',
        \ 'haskell'    : 'ghci',
        \ 'javascript' : 'node'
        \ }
    let cmd = empty(a:command) ? (has_key(map, &filetype) ? map[&filetype] : '') : a:command
    execute 'ScreenShell ' . cmd
endfunction

command! -bar ScreenEnterHandler call <SID>ScreenSetup(1) "{{{1
command! -bar ScreenExitHandler  call <SID>ScreenSetup(0)
function! <SID>ScreenSetup(setup)
    let bind   = &filetype == 'clojure' ? '<Leader>x' : '<Leader><Leader>'
    let select = &filetype == 'clojure' ? ':call PareditSelectCurrentForm()<CR>' : 'vip'
    let topsel = &filetype == 'clojure' ? ':call searchpair("(","",")","r")<CR>v%' : 'VggoG'

    if a:setup
        " RECURSIVE map for cascading mappings
        execute 'vmap ' . bind . ' :ScreenSend<CR>'
        execute 'nmap ' . bind . ' mp' . select . bind . '`p'
        execute 'imap ' . bind . ' <C-\><C-o><C-\><C-n>' . bind

        execute 'nmap <Leader><C-f> mp' . topsel . bind . '`p'
        execute 'imap <Leader><C-f> <C-\><C-o><C-\><C-n><Leader><C-f>'

        nmap <Leader>Q :ScreenQuit<CR>
    else
        if !g:ScreenShellActive
            execute 'silent! vunmap ' . bind
            execute 'silent! nunmap ' . bind
            execute 'silent! iunmap ' . bind

            silent! nunmap <Leader><C-f>
            silent! iunmap <Leader><C-f>

            silent! nunmap <Leader>Q
        endif
    endif
endfunction


command! -bar ClojureTagJump call <SID>ClojureTagJump(expand('<cword>')) "{{{1
function! <SID>ClojureTagJump(word)
    execute 'tag ' . substitute(a:word, '\v.*/(.*)', '\1', '') | normal zz
endfunction


command! -bar OrgBufferSetup call <SID>OrgBufferSetup() "{{{1
function! <SID>OrgBufferSetup()
    " RECURSIVE maps for <Plug> mappings
    map  <silent> <buffer> <4-[> <Plug>OrgPromoteHeadingNormal
    imap <silent> <buffer> <4-[> <C-\><C-o><Plug>OrgPromoteHeadingNormal
    map  <silent> <buffer> <4-]> <Plug>OrgDemoteHeadingNormal
    imap <silent> <buffer> <4-]> <C-\><C-o><Plug>OrgDemoteHeadingNormal

    map  <silent> <buffer> <M-J> <Plug>OrgMoveSubtreeDownward
    imap <silent> <buffer> <M-J> <C-\><C-o><Plug>OrgMoveSubtreeDownward
    map  <silent> <buffer> <M-K> <Plug>OrgMoveSubtreeUpward
    imap <silent> <buffer> <M-K> <C-\><C-o><Plug>OrgMoveSubtreeUpward

    map  <silent> <buffer> <M-H> <Plug>OrgPromoteSubtreeNormal
    imap <silent> <buffer> <M-H> <C-\><C-o><Plug>OrgPromoteSubtreeNormal
    map  <silent> <buffer> <M-L> <Plug>OrgDemoteSubtreeNormal
    imap <silent> <buffer> <M-L> <C-\><C-o><Plug>OrgDemoteSubtreeNormal

    map  <silent> <buffer> <4-CR> <Plug>OrgNewHeadingBelowNormal
    imap <silent> <buffer> <4-CR> <C-\><C-o><Plug>OrgNewHeadingBelowNormal
    map  <silent> <buffer> <M-CR> <Plug>OrgNewHeadingBelowNormal<C-\><C-o><Plug>OrgDemoteHeadingNormal<End>
    imap <silent> <buffer> <M-CR> <C-\><C-n><M-CR>

    " Please don't remap core keybindings!
    silent! iunmap <buffer> <C-d>
    silent! iunmap <buffer> <C-t>
endfunction


command! -bar Open call <SID>Open(expand('<cWORD>')) "{{{1
function! <SID>Open(word)
    " Parameter is a whitespace delimited WORD, thus URLs may not contain spaces.
    " Worth the simple implementation IMO.
    let rdelims = "\"');>"
    let capture = 'https?://[^' . rdelims . ']+|(https?://)@<!www\.[^' . rdelims . ']+'
    let pattern = '\v.*(' . capture . ')[' . rdelims . ']?.*'
    if match(a:word, pattern) != -1
        let url = substitute(a:word, pattern, '\1', '')
        echo url
        return system('open ' . shellescape(url))
    else
        echo 'No URL found!'
    endif
endfunction


command! -nargs=? -complete=command -bar Qfdo call <SID>Qfdo(<q-args>) "{{{1
function! <SID>Qfdo(expr)
    " Run a command over all lines in the quickfix buffer
    let qflist = getqflist()
    for item in qflist
        execute item['bufnr'] . 'buffer!'
        execute item['lnum'] . a:expr
    endfor
endfunction


command! -bar ToggleQuickfixWindow call <SID>ToggleQuickfixWindow() "{{{1
function! <SID>ToggleQuickfixWindow()
    if &buftype ==# 'quickfix'
        cclose
    else
        copen
    endif
endfunction


command! -nargs=+ -complete=file -bar TabOpen call <SID>TabOpen(<f-args>) "{{{1
function! <SID>TabOpen(file, ...)
    for t in range(tabpagenr('$'))
        for b in tabpagebuflist(t + 1)
            if a:file ==# expand('#' . b . ':p')
                execute ':' . (t + 1) . 'tabnext'
                execute ':' . b       . 'wincmd w'
                return
            endif
        endfor
    endfor

    execute a:0 ? join(a:000) : 'tabedit ' . a:file
endfunction


command! -bar TabmoveNext call <SID>Tabmove(1) " {{{1
command! -bar TabmovePrev call <SID>Tabmove(-1)
function! <SID>Tabmove(n)
    if version >= 703 && has('patch591')
        execute 'tabmove ' . printf('%+d', a:n)
    else
        let nr = a:n > 0 ? tabpagenr() + a:n - 1 : tabpagenr() - a:n - 3
        execute 'tabmove ' . (nr < 0 ? 0 : nr)
    endif
endfunction


command! -bar RunCurrentFile call <SID>RunCurrentFile() "{{{1
function! <SID>RunCurrentFile()
    let map = {
        \ 'ruby'    : 'ruby',
        \ 'clojure' : 'clojure'
    \ }
    if &filetype == 'vim'
        source %
    elseif has_key(map, &filetype)
        silent execute '! ' . map[&filetype] . ' % | $PAGER' | redraw!
    endif
endfunction


command! -bar RunCurrentMiniTestCase call <SID>RunCurrentMiniTestCase() "{{{1
" Run a single MiniTest::Spec test case
function! <SID>RunCurrentMiniTestCase()
    " Get the line number for the last assertion
    let line = search('\vit .* do', 'bcnW')
    if !line | return | endif

    " Construct the test name
    let rbstr = matchlist(getline(line), '\vit (.*) do')[1]
    let reg_save = @r
    execute 'ruby VIM.command(%q(let @r = "%s") % ' . rbstr . '.gsub(/\W+/, %q(_)).downcase)'
    let name = @r
    let @r = reg_save

    " Run the test
    silent execute '! ruby % --name /test.*' . name . '/ | $PAGER' | redraw!
endfunction


command! -bar MapReadlineUnicodeBindings call <SID>MapReadlineUnicodeBindings() "{{{1
function! <SID>MapReadlineUnicodeBindings()
    if filereadable(expand('~/.inputrc'))
        for line in readfile(expand('~/.inputrc'))
            if line =~# '\v<U\+\x{4,6}>'
                " Example: "\el": "λ" # U+03BB
                let toks = split(line)
                let key  = substitute(toks[0], '\v.*\\e(.).*', '\1', '')
                let char = substitute(toks[1], '\v.*"(.+)".*', '\1', '')

                " By convention, we'll always map as Meta-.
                let bind = '<Esc>' . key
                execute 'noremap! ' . bind . ' ' . char
            endif
        endfor
    endif
endfunction


command! -bar CapturePane call <SID>CapturePane() "{{{1
function! <SID>CapturePane()
    " Tmux-esque capture-pane
    let buf = bufnr('%')
    let tab = len(tabpagebuflist()) > 1
    wincmd q
    if tab | execute 'normal gT' | endif
    execute buf . 'sbuffer'
    wincmd L
endfunction


command! -nargs=+ -complete=command -bar Capture call <SID>Capture(<q-args>) "{{{1
command! CaptureMaps
    \ execute 'Capture verbose map \| silent! verbose map!' |
    \ :%! ruby -Eutf-8 -e 'puts $stdin.read.chars.map { |c| c.unpack("U").pack "U" rescue "UTF-8-ERROR" }.join.gsub(/\n\t/, " \" ")'
" Redirect output of given commands into a scratch buffer
function! <SID>Capture(cmd)
    try
        redir @r
        execute 'silent! ' . a:cmd
    finally
        redir END
        new | setlocal buftype=nofile filetype=vim | normal "rp
    endtry
endfunction

command! -nargs=* -complete=file -bang -bar Org call <SID>Org('<bang>', <f-args>) "{{{1
function! <SID>Org(bang, ...)
    let tab = empty(a:bang) ? 'tab' : ''

    if a:0
        for f in a:000
            execute tab . 'edit ' . join([g:org_home, f . '.org'], '/')
            execute 'lcd ' . g:org_home
        endfor
    else
        if empty(a:bang) | tabnew | endif
        execute 'lcd ' . g:org_home | CtrlP
    endif
endfunction


" Say {{{1
if executable('/usr/bin/say')
    command! -nargs=1 -complete=command -bar Say call system('say ' . shellescape(<q-args>))
else
    command! -nargs=1 -complete=command -bar Say call system('espeak -ven-us ' . shellescape(<q-args>))
endif


" Interleave {{{1
command! -bar -range Interleave
    \ '<,'>! ruby -e 'l = $stdin.read.lines; puts l.take(l.count/2).zip(l.drop l.count/2).join'


" Hitest {{{1
" http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
command! -bar Hitest
    \ 45vnew |
    \ source $VIMRUNTIME/syntax/hitest.vim |
    \ setlocal synmaxcol=5000 nocursorline nocursorcolumn


""" Utility functions {{{1

function! CwordOrSel(...) " {{{1
    if a:0 && a:1
        normal gv"vy
        return @v
    else
        return expand('<cword>')
    endif
endfunction
