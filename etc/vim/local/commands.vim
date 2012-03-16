""" Library of commands

command! -nargs=+ -bar Mapall call <SID>Mapall(<f-args>) " {{{1
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
        let paropts = a:0 == 2 ? a:2 : 'q1re\ B=_A_a.,?'
        execute 'set' . local . ' textwidth=' . a:1
        execute 'set' . local . ' formatprg=par\ ' . paropts . '\ ' . a:1
    else
        echo 'tw=' . &textwidth . ' fp=' . &formatprg
    endif
endfunction


command! -nargs=? -bang -bar SetAutowrap call <SID>SetAutowrap('<bang>', <f-args>) "{{{1
function! <SID>SetAutowrap(bang, ...)
    let status = empty(a:bang) ? (a:0 ? a:1 : 'report') : (&formatoptions =~ 'a' ? 'off' : 'on')

    if status == 'report'
        echo &formatoptions =~ 'a' ? 'Autowrap is on' : 'Autowrap is off'
    elseif status == 'on'
        execute 'setlocal formatoptions+=t formatoptions+=a formatoptions+=w'
    else
        execute 'setlocal formatoptions-=t formatoptions-=a formatoptions-=w'
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


command! -bar Todo call <SID>Todo() "{{{1
function! <SID>Todo()
    let words = ['TODO', 'FIXME', 'NOTE', 'WARNING', 'DEBUG', 'HACK', 'XXX']

    " Fugitive detects Git repos for us
    if exists(':Ggrep')
        execute 'silent! Ggrep! -Ew "' . join(words,'|') . '" ' . shellescape(getcwd(), 1)
    elseif exists(':Ack')
        execute 'silent! Ack! -w "' . join(words,'\|') . '"'
    else
        execute 'silent! grep! -r -Ew "' . join(words,'\|') . '" .'
    endif

    redraw!
endfunction


command! -bar LispBufferSetup call <SID>LispBufferSetup() "{{{1
function! <SID>LispBufferSetup()
    let b:delimitMate_quotes = '"'
    SetWhitespace 2 8

    nnoremap <buffer> <Leader><C-n> :StartNailgunServer \| silent edit<CR>
    noremap! <buffer> <C-l>         ->
    noremap  <buffer> <4-CR>        A<Space>;<Space>
    noremap! <buffer> <4-CR>        <C-\><C-o>A<Space>;<Space>
    nnoremap <buffer> ==            :normal m`=a(``<CR>
    nnoremap <buffer> =p            :normal m`=ap``<CR>
    nnoremap <buffer> <C-]>         :<C-u>ClojureTagJump<CR>

    "
    " VimClojure
    "

    " RECURSIVE map for <Plug> mappings
    nmap <silent> <buffer> K         <Plug>ClojureSourceLookupWord
    nmap <silent> <buffer> <Leader>d <Plug>ClojureSourceLookupWord
    nmap <silent> <buffer> <Leader>q <Plug>ClojureCloseResultBuffer
    nmap <silent> <buffer> <Leader>r <Plug>ClojureRequireFileAll

    " cf. ScreenSetup
    vmap <silent> <buffer> <Leader>x <Plug>ClojureEvalBlock
    nmap <silent> <buffer> <Leader>x m`va(<Leader>x``
    imap <silent> <buffer> <Leader>x <C-\><C-n><Leader>x<Right>

    "
    " Paredit
    "

    " Initialize Paredit, but don't create any mappings
    let g:paredit_mode = 0
    call PareditInitBuffer()
    let g:paredit_mode = 1

    " Movement
    nnoremap <silent> <buffer> [[ :<C-u>call PareditFindDefunBck()<CR>zz
    nnoremap <silent> <buffer> ]] :<C-u>call PareditFindDefunFwd()<CR>zz
    nnoremap <silent> <buffer> (  :<C-u>call PareditFindOpening(0,0,0)<CR>
    nnoremap <silent> <buffer> )  :<C-u>call PareditFindClosing(0,0,0)<CR>

    " Auto-balancing insertion
    inoremap <silent> <buffer> <expr> ( PareditInsertOpening('(',')')
    inoremap <silent> <buffer> <expr> ) PareditInsertClosing('(',')')
    inoremap <silent> <buffer> <expr> [ PareditInsertOpening('[',']')
    inoremap <silent> <buffer> <expr> ] PareditInsertClosing('[',']')
    inoremap <silent> <buffer> <expr> { PareditInsertOpening('{','}')
    inoremap <silent> <buffer> <expr> } PareditInsertClosing('{','}')

    " Select next/prev item in list
    nnoremap <silent> <buffer> <Leader>j :<C-u>call PareditSelectListElement(1)<CR>
    vnoremap <silent> <buffer> <Leader>j <C-c>:<C-u>call PareditSelectListElement(1)<CR>
    nnoremap <silent> <buffer> <Leader>k :<C-u>call PareditSelectListElement(0)<CR>
    vnoremap <silent> <buffer> <Leader>k o<C-c><Left>:<C-u>call PareditSelectListElement(0)<CR>

    " Insert at beginning, end of form
    nnoremap <silent> <buffer> <Leader>I :<C-u>call PareditFindOpening(0,0,0)<CR>a
    nnoremap <silent> <buffer> <Leader>l :<C-u>call PareditFindClosing(0,0,0)<CR>i

    " Wrap word/form
    nnoremap <silent> <buffer> <Leader>W :<C-u>call PareditWrap('(',')')<CR>

    " Wrap word/form/selection, then insert at end
    nnoremap <silent> <buffer> <Leader>w :<C-u>call PareditWrap('(',')')<CR>%i
    vnoremap <silent> <buffer> <Leader>w :<C-u>call PareditWrapSelection('(',')')<CR>i

    " Wrap form/selection, then insert in front
    nnoremap <silent> <buffer> <Leader>i vi(:<C-u>call PareditWrapSelection('(',')')<CR>%i<Space><Left>
    vnoremap <silent> <buffer> <Leader>i :<C-u>call PareditWrapSelection('(',')')<CR>%a<Space><Left>

    " paredit-raise-sexp
    nnoremap <silent> <buffer> <Leader>o :<C-u>call PareditRaiseSexp()<CR>

    " Toggle Clojure (comment)
    nnoremap <silent> <buffer> <Leader>cc m`:<C-u>call PareditToggleClojureComment()<CR>=a(``
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

    if empty(system('nc -z 127.0.0.1 ' . g:vimclojure#NailgunPort . ' &>/dev/null && echo 1'))
        silent! execute '! clojure --lein-nailgun ' . g:vimclojure#NailgunPort . ' &>/dev/null &'
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


command! -nargs=? -bar Screen call <SID>Screen(<q-args>) "{{{1
function! <SID>Screen(command)
    let map = {
        \ 'ruby'       : 'irb -f',
        \ 'clojure'    : 'clojure --lein repl',
        \ 'python'     : 'python',
        \ 'scheme'     : 'scheme',
        \ 'javascript' : 'node'
        \ }
    let cmd = empty(a:command) ? (has_key(map, &filetype) ? map[&filetype] : '') : a:command
    execute 'ScreenShell ' . cmd
endfunction

command! -bar ScreenEnterHandler call <SID>ScreenSetup(1) "{{{1
command! -bar ScreenExitHandler  call <SID>ScreenSetup(0)
function! <SID>ScreenSetup(setup)
    if a:setup
        " RECURSIVE map for cascading mappings
        vmap <Leader><Leader> :ScreenSend<CR>
        nmap <Leader><Leader> m`:execute 'normal ' . (&filetype == 'clojure' ? 'va(' : 'vip')<CR><Leader><Leader>``
        imap <Leader><Leader> <C-\><C-n><Leader><Leader><Right>

        nmap <Leader><C-f> m`:execute 'normal ' . (&filetype == 'clojure' ? 'vip' : 'VggoG')<CR><Leader><Leader>``
        imap <Leader><C-f> <C-\><C-n><Leader><C-f><Right>

        nmap <Leader>Q :ScreenQuit<CR>
    else
        if !g:ScreenShellActive
            silent! vunmap <Leader><Leader>
            silent! nunmap <Leader><Leader>
            silent! iunmap <Leader><Leader>

            silent! nunmap <Leader><C-f>
            silent! iunmap <Leader><C-f>

            silent! nunmap <Leader>Q
        endif
    endif
endfunction


command! -bar ClojureTagJump call <SID>ClojureTagJump(expand('<cword>')) "{{{1
function! <SID>ClojureTagJump(word)
    execute 'tag ' . substitute(a:word, '\v.*/(.*)', '\1', '')
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


command! -nargs=? Qfdo call <SID>Qfdo(<q-args>) "{{{1
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
    if len(filter(tabpagebuflist(), 'getbufvar(v:val, "&buftype") ==# "quickfix"'))
        cclose
    else
        copen
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


command! -bar RubyFold call <SID>RubyFold() "{{{1
function! <SID>RubyFold()
    " Create folds for Ruby method definitions using the ruby text object
    setlocal foldmethod=manual
    normal mrgg

    while search('\v^\s*def ', 'W')
        normal v%zfj0
    endwhile

    normal `r
endfunction


command! -bar RunCurrentMiniTestCase call <SID>RunCurrentMiniTestCase() "{{{1
" Run a single MiniTest::Spec test case
function! <SID>RunCurrentMiniTestCase()
    " Get the line number for the last assertion
    let line = search('\vit .* do', 'bcnW')
    if !line | return | endif

    " Construct the test name
    let rbstr = matchlist(getline(line), '\vit (.*) do')[1]
    execute 'ruby VIM.command(%q(let @r = "%s") % ' . rbstr . '.gsub(/\W+/, %q(_)).downcase)'
    let name = @r

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
                let bind = key =~# '\v[<>]' ? '' . key : '<M-' . key . '>'
                execute 'noremap! ' . bind . ' ' . char
            endif
        endfor
    endif
endfunction


command! -nargs=? -bar CapturePane call <SID>CapturePane() "{{{1
function! <SID>CapturePane()
    " Tmux-esque capture-pane
    let buf = bufnr('%')
    let tab = len(tabpagebuflist()) > 1
    wincmd q
    if tab | execute 'normal gT' | endif
    execute buf . 'sbuffer'
    wincmd L
endfunction


command! -nargs=+ Capture call <SID>Capture(<q-args>) "{{{1
command! CaptureMaps
    \ execute 'Capture verbose map | silent! verbose map!' |
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

command! -nargs=* -bang -bar Org call <SID>Org('<bang>', <f-args>) "{{{1
function! <SID>Org(bang, ...)
    let tab = empty(a:bang) ? 'tab' : ''
    let orgdir = expand('~/Documents/Org')

    if a:0
        for f in a:000
            execute tab . 'edit ' . join([orgdir, f . '.org'], '/')
            execute 'lcd ' . orgdir
        endfor
    else
        if empty(a:bang) | tabnew | endif
        execute 'lcd ' . orgdir | CommandT
    endif
endfunction


" Say {{{1
if executable('/usr/bin/say')
    command! -nargs=1 -bar Say call system('say ' . shellescape(<q-args>))
else
    command! -nargs=1 -bar Say call system('espeak -ven-us ' . shellescape(<q-args>))
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


""" Utility functions

function! CwordOrSel(...)
    if a:0 && a:1
        normal gv"vy
        return @v
    else
        return expand('<cword>')
    endif
endfunction
