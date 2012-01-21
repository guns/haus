""" Assorted Commands and Functions

command! -nargs=+ -bar Mapall   call <SID>Mapall('nore', <f-args>) "{{{1
command! -nargs=+ -bar Remapall call <SID>Mapall('',     <f-args>)
function! <SID>Mapall(prefix, map, ...)
    " FIXME: Make me work better with <plug> mappings
    if a:0 == 1
        let esc    = '<Esc>'
        let seq    = a:1
        let endesc = ''
    elseif a:0 == 2
        let esc    = a:1
        let seq    = a:2
        let endesc = ''
    elseif a:0 == 3
        let esc    = a:1
        let seq    = a:2
        let endesc = a:3
    else
        return
    endif

    execute a:prefix . 'map  <special> ' . a:map . ' ' . seq
    execute a:prefix . 'map! <special> ' . a:map . ' ' . esc . seq . endesc
endfunction


command! -nargs=+ -bang PreserveMap call <SID>PreserveMap('<bang>', <f-args>) "{{{1
function! <SID>PreserveMap(bang, new, old)
    " Alias and nullify old mapping
    execute 'noremap' . a:bang . ' <special> ' . a:new . ' ' . a:old
    execute     'map' . a:bang . ' <special> ' . a:old . ' <NOP>'
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
        execute 'setlocal formatoptions+=t formatoptions+=a formatoptions+=w formatoptions+=c'
    else
        execute 'setlocal formatoptions-=t formatoptions-=a formatoptions-=w'
    endif
endfunction


command! -nargs=? -bang -bar SetMatchParen call <SID>SetMatchParen('<bang>', <f-args>) "{{{1
function! <SID>SetMatchParen(bang)
    let loaded = exists('g:loaded_matchparen') && g:loaded_matchparen == 1

    if empty(a:bang)
        execute loaded ? 'echo "MatchParen is on!"' : 'echo "MatchParen is off!"'
    else
        execute loaded ? 'execute "NoMatchParen" | echo "MatchParen off!"' : 'execute "DoMatchParen" | echo "MatchParen on!"'
    endif
endfunction


command! -bar SynStack call <SID>SynStack() "{{{1
function! <SID>SynStack()
    " TextMate style syntax highlighting stack for word under cursor
    " http://vimcasts.org/episodes/creating-colorschemes-for-vim/
    if !exists("*synstack")
        return
    endif
    echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
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
        execute 'silent! grep! -r -Pw "' . join(words,'\|') . '" .'
    endif

    redraw!
endfunction


command! -bar ClojureToggleFormComment call <SID>ClojureToggleFormComment() "{{{1
function! <SID>ClojureToggleFormComment()
    normal m`vabv
    let word = substitute(getline(line("'<")), '\v.{' . col("'<") . '}(\S*).*', '\1', '')

    if word =~# 'comment'
        execute 'normal gvov dw'
    else
        execute 'normal gvovacomment '
    endif

    normal =ab``
endfunction

command! -bar StartNailgunServer call <SID>StartNailgunServer() "{{{1
function! <SID>StartNailgunServer()
    if g:vimclojure#WantNailgun
        echo 'WantNailgun option already set!'
        return
    endif
    let g:vimclojure#WantNailgun = 1

    if empty(system('nc -z 127.0.0.1 2113 &>/dev/null && echo 1'))
        silent! execute '! clojure --nailgun &>/dev/null & until nc -z 127.0.0.1 2113 &>/dev/null; do echo -n .; sleep 1; done'
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

    echo 'Nailgun server started'
endfunction


command! -bar StopNailgunServer call <SID>StopNailgunServer() "{{{1
function! <SID>StopNailgunServer()
    let g:vimclojure#WantNailgun = 0

    silent! execute '!' . g:vimclojure#NailgunClient . ' ng-stop &>/dev/null &' | redraw!

    augroup NailgunServer
        autocmd!
    augroup END

    echo 'Killing Nailgun server'
endfunction


command! -bar ClojureSetupBufferLocalSettings call <SID>ClojureSetupBufferLocalSettings() "{{{1
function! <SID>ClojureSetupBufferLocalSettings()
    let b:delimitMate_quotes = '"'
    SetWhitespace 2 8

    call PareditInitBuffer()

    nnoremap <buffer> <Leader><C-n> :StartNailgunServer<CR>
    noremap! <buffer> <C-l>         ->
    nnoremap <buffer> ==            :normal m`=ab``<CR>
    nnoremap <buffer> =p            :normal m`=ap``<CR>
    nnoremap <buffer> <Leader>cc    :ClojureToggleFormComment<CR>

    " Extra VimClojure mappings
    nmap <buffer> <Leader>d <Plug>ClojureSourceLookupWord
    nmap <buffer> <Leader>q <Plug>ClojureCloseResultBuffer
endfunction


command! -nargs=? -bar Screen call <SID>Screen(<q-args>) "{{{1
function! <SID>Screen(command)
    let map = {
        \ 'ruby'       : 'irb -f',
        \ 'clojure'    : 'clojure --leinrepl',
        \ 'python'     : 'python',
        \ 'scheme'     : 'scheme',
        \ 'javascript' : 'node'
        \ }
    let chdir = 'cd "' . getcwd() . '"'
    let cmd = empty(a:command) ? (has_key(map, &filetype) ? map[&filetype] : '') : a:command
    execute 'ScreenShell ' . chdir . '; ' . cmd
endfunction

command! -bar ScreenEnterHandler call <SID>ScreenSetup(1) "{{{1
command! -bar ScreenExitHandler  call <SID>ScreenSetup(0)
function! <SID>ScreenSetup(setup)
    if a:setup
        vmap <Leader><Leader> :ScreenSend<CR>
        nmap <Leader><Leader> m`vip<Leader><Leader>``
        imap <Leader><Leader> <Esc><Leader><Leader><Right>

        nmap <Leader><C-f>    m`vab<Leader><Leader>``
        imap <Leader><C-f>    <Esc><Leader><C-f><Right>

        nmap <Leader>Q        :ScreenQuit<CR>
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
    endif

    echo 'No URL or path found!'
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


" Ctags {{{1
command! -bar Ctags silent ! ctags -R


" Say {{{1
if g:VIM_PLATFORM == 'macunix'
    command! -nargs=1 -bar Say call system('say ' . <q-args>)
elseif g:VIM_PLATFORM == 'unix'
    command! -nargs=1 -bar Say call system('espeak -ven-us "' . <q-args> . '"')
endif


" Interleave {{{1
command! -bar -range Interleave
    \ '<,'>! ruby -e 'l = STDIN.read.lines; puts l.take(l.count/2).zip(l.drop l.count/2).join'


" Hitest {{{1
" http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
command! -bar Hitest
    \ 45vnew |
    \ source $VIMRUNTIME/syntax/hitest.vim |
    \ setlocal synmaxcol=5000 nocursorline nocursorcolumn


" DiggOrig {{{1
" From vimrc_example.vim
" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
command! -bar DiffOrig
    \ vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis
