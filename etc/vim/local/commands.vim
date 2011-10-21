""" Assorted Commands and Functions

" FIXME: Make me work better with <plug> mappings {{{1
" DRY up repetitive noremap, noremap! invocations
command! -nargs=+ -bar Mapall   call <SID>Mapall('nore', <f-args>)
command! -nargs=+ -bar Remapall call <SID>Mapall('',     <f-args>)
function! <SID>Mapall(prefix, map, ...)
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


" Alias and nullify old mapping {{{1
command! -nargs=+ -bang PreserveMap call <SID>PreserveMap('<bang>', <f-args>)
function! <SID>PreserveMap(bang, new, old)
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


command! -nargs=* -bang -bar SetTextwidth call <SID>SetTextwidth('<bang>', <f-args>)
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


" TextMate style syntax highlighting stack for word under cursor "{{{1
" http://vimcasts.org/episodes/creating-colorschemes-for-vim/
command! SynStack call <SID>SynStack()
function! <SID>SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunction


" TextMate's Todo.bundle via grep + quickfix {{{1
command! Todo call <SID>Todo()
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


" Better ScreenShell command {{{1
command! -nargs=? -bar Screen call <SID>Screen(<q-args>)
function! <SID>Screen(command)
    let map = {
        \ 'ruby'       : 'irb',
        \ 'python'     : 'python',
        \ 'scheme'     : 'scheme',
        \ 'javascript' : 'node'
        \ }
    let chdir = 'cd "' . getcwd() . '"'
    let cmd = empty(a:command) ? (has_key(map, &filetype) ? map[&filetype] : '') : a:command
    execute 'ScreenShellVertical ' . chdir . '; ' . cmd
endfunction


" Simple Open command: {{{1
" Parameter is a whitespace delimited WORD, thus URLs may not contain spaces.
" Worth the simple implementation IMO.
command! Open call <SID>Open(expand('<cWORD>'))

function! <SID>Open(word)
    " Extract web URLs
    let rdelims = "\"');>"
    let capture = 'https?://[^' . rdelims . ']+|(https?://)@<!www\.[^' . rdelims . ']+'
    let pattern = '\v.*(' . capture . ')[' . rdelims . ']?.*'
    if match(a:word, pattern) != -1
        return <SID>OpenURL(substitute(a:word, pattern, '\1', ''))
    endif

    echo 'No URL or path found!'
endfunction

function! <SID>OpenURL(url)
    echo a:url
    if g:VIM_PLATFORM == 'macunix'
        call system('open ' . shellescape(a:url))
    elseif g:VIM_PLATFORM == 'unix'
        call system('chrome ' . shellescape(a:url))
    endif
endfunction


" Run a command over all lines in the quickfix buffer {{{1
command! -nargs=? Qfdo call <SID>Qfdo(<q-args>)
function! <SID>Qfdo(expr)
    let qflist = getqflist()
    for item in qflist
        execute item['bufnr'] . 'buffer!'
        execute item['lnum'] . a:expr
    endfor
endfunction


" Source or run current file {{{1
command! RunCurrentFile call <SID>RunCurrentFile()
function! <SID>RunCurrentFile()
    if &filetype == 'vim'
        source %
    elseif &filetype == 'ruby'
        silent execute '! ruby % | $PAGER' | redraw!
    endif
endfunction


" Create folds for Ruby method definitions using the ruby text object {{{1
command! RubyFold call <SID>RubyFold()
function! <SID>RubyFold()
    setlocal foldmethod=manual
    normal mrgg

    while search('\v^\s*def ', 'W')
        normal v%zfj0
    endwhile

    normal `r
endfunction


" Run a single MiniTest::Spec test case {{{1
command! RunCurrentMiniTestCase call <SID>RunCurrentMiniTestCase()
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


" Tmux-esque capture-pane {{{1
command! -nargs=? -bar CapturePane call <SID>CapturePane()
function! <SID>CapturePane()
    let buf = bufnr('%')
    let tab = len(tabpagebuflist()) > 1
    wincmd q
    if tab | execute 'normal gT' | endif
    execute buf . 'sbuffer'
    wincmd L
endfunction


" Exuberant Ctags {{{1
command! Ctags silent ! ctags -R -f .tags


" Voice command {{{1
if g:VIM_PLATFORM == 'macunix'
    command! -nargs=1 -bar Say call system('say ' . <q-args>)
elseif g:VIM_PLATFORM == 'unix'
    command! -nargs=1 -bar Say call system('espeak -ven-us "' . <q-args> . '"')
endif


" Redirect output of given commands into a scratch buffer {{{1
command! -nargs=+ Capture call <SID>Capture(<q-args>)
function! <SID>Capture(cmd)
    try
        redir @r
        execute 'silent ' . a:cmd
    finally
        redir END
        new | setlocal buftype=nofile filetype=vim | normal "rp
    endtry
endfunction

command! CaptureMaps
    \ execute 'Capture verbose map | silent verbose map!' |
    \ while search('\v^\tLast', 'W') |
    \   execute 'normal kJa" j' |
    \ endwhile


" Parse and map Readline's Unicode character bindings {{{1
command! MapReadlineUnicodeBindings call <SID>MapReadlineUnicodeBindings()
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


" Open ORG-mode files {{{1
command! -nargs=* -bang -bar Org call <SID>Org('<bang>', <f-args>)
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


" A sometimes useful command for interleaving an even number of lines {{{1
command! -range Interleave
    \ '<,'>! ruby -e 'l = STDIN.read.lines; puts l.take(l.count/2).zip(l.drop l.count/2).join'


" http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim {{{1
command! Hitest
    \ 45vnew |
    \ source $VIMRUNTIME/syntax/hitest.vim |
    \ setlocal synmaxcol=5000 nocursorline nocursorcolumn


" From vimrc_example.vim: {{{1
" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
command! DiffOrig
    \ vert new | set bt=nofile | r # | 0d_ | diffthis | wincmd p | diffthis
