""" Library of commands

" Call shell commands silently, suppressing all output
command! -nargs=+ -complete=shellcmd Sh call system(<q-args>)

" Will place history in global input history instead of command history (which
" may be a good thing in some cases), as well as offering direct control of
" completions.
function! Prompt(...)
    if a:0 == 3
        let buf = input(a:1, a:2, a:3)
    elseif a:0 == 2
        let buf = input(a:1, a:2, 'file')
    elseif a:0 == 1
        let buf = input(a:1, '', 'file')
    endif
    if !empty(buf) | execute a:1 . buf | endif
endfunction

command! -nargs=+ -complete=command -bar Mapall      call <SID>Mapall('nore', '',         <f-args>) " {{{1
command! -nargs=+ -complete=command -bar ReMapall    call <SID>Mapall('',     '',         <f-args>)
command! -nargs=+ -complete=command -bar BufMapall   call <SID>Mapall('nore', '<buffer>', <f-args>)
command! -nargs=+ -complete=command -bar BufReMapall call <SID>Mapall('',     '<buffer>', <f-args>)
function! s:Mapall(prefix, mods, ...)
    execute a:prefix . 'map  ' . a:mods . ' '. join(a:000)
    execute a:prefix . 'map! ' . a:mods . ' '. a:1 . ' <Esc>' . join(a:000[1:])
endfunction

command! -nargs=* -bang -bar SetWhitespace call <SID>SetWhitespace('<bang>', <f-args>) "{{{1
function! s:SetWhitespace(bang, ...)
    if a:0
        let local = empty(a:bang) ? 'local' : ''
        execute 'set' . local . ' shiftwidth=' . a:1
        execute 'set' . local . ' softtabstop=' . a:1
        execute 'set' . local . ' tabstop=' . (a:0 == 2 ? a:2 : a:1)
    else
        echo 'sw=' . &shiftwidth . ' sts=' . &softtabstop . ' ts=' . &tabstop
    endif
endfunction

command! -nargs=* -bang -bar SetTextwidth call s:SetTextwidth('<bang>', <f-args>) "{{{1
function! s:SetTextwidth(bang, ...)
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
function! s:SetAutowrap(bang, ...)
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
function! s:SetIskeyword(bang)
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
function! s:SetDiff(bang)
    if empty(a:bang)
        set diff?
    elseif &diff
        windo execute "if expand(\"%:t\") !=# \"index\" | diffoff | setlocal nowrap | endif"
    else
        windo execute "if expand(\"%:t\") !=# \"index\" | diffthis | endif"
    endif
endfunction

command! -bang -bar SetVerbose call <SID>SetVerbose('<bang>') "{{{1
function! s:SetVerbose(bang)
    let enable = !exists('g:SetVerbose')

    if !empty(a:bang)
        call writefile([], '/tmp/verbose.vim')
    end

    if enable
        let g:SetVerbose = 1
        set verbose=100 verbosefile=/tmp/verbose.vim
        echo '♫ BEGIN VERBOSE MODE ♫'
    else
        echo '♫ END VERBOSE MODE ♫'
        set verbose=0 verbosefile=
        unlet! g:SetVerbose
    endif
endfunction

command! -nargs=? -complete=file -bar UndoRemove call <SID>UndoRemove(<f-args>)
function! s:UndoRemove(...)
    let file = undofile(a:0 ? a:1 : expand('%'))
    let s = delete(file) == 0
    echo printf('%successfully deleted %s', s ? 'S' : 'Uns', file)
endfunction

command! -nargs=* -complete=function -bar Profile call <SID>Profile(<f-args>)
function! s:Profile(...)
    profile start /tmp/profile.vim
    for pat in a:000
        if pat =~# '\v^file:'
            execute 'profile file ' . substitute(pat, '\vfile:(.*)', '\1', '')
        else
            execute 'profile func *' . pat . '*'
        endif
    endfor
endfunction

command! -bar SynStack call <SID>SynStack() "{{{1
function! s:SynStack()
    " TextMate style syntax highlighting stack for word under cursor
    " http://vimcasts.org/episodes/creating-colorschemes-for-vim/
    if exists("*synstack")
        echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
    endif
endfunction

command! -nargs=? -bar -complete=file Todo call <SID>Todo(<f-args>) "{{{1
function! s:Todo(...)
    let words = ['TODO', 'FIXME', 'NOTE', 'WARNING', 'DEBUG', 'HACK', 'XXX']
    let arg = a:0 ? shellescape(expand(a:1), 1) : '.'

    " Fugitive detects Git repos for us
    if exists(':Ggrep')
        execute 'silent! Ggrep! -Ew "' . join(words,'|') . '" ' . (a:0 ? arg : shellescape(getcwd(), 1))
    elseif exists(':Ack')
        execute 'silent! Ack! -w "' . join(words,'\|') . '" ' . arg
    else
        execute 'silent! grep! -r -Ew "' . join(words,'\|') . '" ' . arg
    endif
endfunction

command! -bar Ctags call <SID>Ctags() "{{{1
function! s:Ctags()
    let cmd = (&filetype == 'javascript') ? 'jsctags.js -f .jstags ' . shellescape(expand('%')) : 'ctags -R'
    execute 'Sh (' . cmd . '; notify --audio) >/dev/null 2>&1 &' | echo cmd
endfunction

function! MarkdownFoldExpr(lnum)
    if getline(a:lnum) =~# '\v^#' || getline(a:lnum + 1) =~# '\v^[=-]+$'
        return '>1'
    else
        return '='
    endif
endfunction

function! ShellFoldExpr(lnum)
    if getline(a:lnum) =~# '\v^\s*\#\#\#\s' && empty(getline(a:lnum - 1))
        return '>1'
    else
        return '='
    endif
endfunction

function! CFoldExpr(lnum)
    let line = getline(a:lnum)
    if line[0] == '{'
        return '>1'
    elseif getline(a:lnum - 1)[0] == '}'
        return '0'
    else
        return '='
    endif
endfunction

function! DiffFoldExpr(lnum) "{{{1
    if getline(a:lnum) =~# '\v^diff>'
        return '>1'
    elseif getline(a:lnum - 3) =~# '\v^-- '
        return '0'
    else
        return '='
    endif
endfunction

function! RubyFoldExpr(lnum) "{{{1
    if getline(a:lnum) =~# '\v^\s*def'
        return '>1'
    elseif getline(a:lnum + 1) =~# '\v^\s{0,2}#'
        return 's1'
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

function! VimFoldExpr(lnum) "{{{1
    let line = getline(a:lnum)
    if line =~# '\v\{\{\{\d*\s*$'
        return '>1'
    elseif line =~# '\v^\s*aug%[roup] END'
        return '='
    elseif line =~# '\v^\s*(fu%[nction]|com%[mand]|aug%[roup])'
        return '>1'
    elseif line[0] ==# '"' && getline(a:lnum - 1)[0] !=# '"'
        return '>1'
    else
        return '='
    endif
endfunction

function! VimHelpFoldExpr(lnum) "{{{1
    let line = getline(a:lnum)
    if line =~# '\v\*\S+\*\s*$'
        return getline(a:lnum - 1) =~# '\v\*\S+\*\s*$' ? '=' : '>1'
    elseif line =~# '\v\~$'
        return '>1'
    else
        return '='
    endif
endfunction

function! LispFoldExpr(lnum) "{{{1
    let line = getline(a:lnum)
    if line[0] ==# '('
        return '>1'
    elseif line[0] ==# ';' && getline(a:lnum - 1)[0] !=# ';'
        return '>1'
    else
        return '='
    endif
endfunction

command! -bar LispBufferSetup call <SID>LispBufferSetup() "{{{1
function! s:LispBufferSetup()
    let b:loaded_delimitMate = 1
    SetWhitespace 2 8
    setlocal foldmethod=expr foldexpr=LispFoldExpr(v:lnum)

    " Rainbow parens
    call rainbow_parentheses#load(0)
    call rainbow_parentheses#load(1)
    call rainbow_parentheses#load(2)
    call rainbow_parentheses#activate()

    noremap  <silent><buffer> <4-CR> A<Space>;<Space>
    noremap! <silent><buffer> <4-CR> <C-\><C-o>A<Space>;<Space>
endfunction

command! -bar ClojureBufferSetup call <SID>ClojureBufferSetup() "{{{1
function! s:ClojureBufferSetup()
    LispBufferSetup

    vmap     <silent><buffer> <Leader><Leader> <Plug>FireplacePrint
    nmap     <silent><buffer> <Leader><Leader> <Plug>FireplacePrint<Plug>(sexp_outer_list)``
    imap     <silent><buffer> <Leader><Leader> <C-\><C-o><C-\><C-n><Leader><Leader>

    nmap     <silent><buffer> <Leader>X        <Plug>FireplacePrint<Plug>(sexp_outer_top_list)``
    imap     <silent><buffer> <Leader>X        <C-\><C-o><C-\><C-n><Leader>X

    nmap     <silent><buffer> <Leader>x        <Plug>FireplacePrint<Plug>(sexp_inner_element)``
    imap     <silent><buffer> <Leader>x        <C-\><C-o><C-\><C-n><Leader>x

    nnoremap <silent><buffer> <Leader>r        :Require<CR>
    nnoremap <silent><buffer> <Leader>R        :call fireplace#eval('(user/refresh)')<CR>
    nnoremap <silent><buffer> <LocalLeader>C   :Connect<Space>
    nnoremap <silent><buffer> <LocalLeader>cp  :call fireplace#eval('(user/classpath)')<CR>
    nnoremap <silent><buffer> <LocalLeader>cs  :call <SID>ClojureCheatSheet('.')<CR>
    nnoremap <silent><buffer> <LocalLeader>cS  :call <SID>ClojureCheatSheet(input('Namespace filter: '))<CR>
    nnoremap <silent><buffer> <LocalLeader>e   :call <SID>ClojurePprint('*e')<CR>
    nnoremap <silent><buffer> <LocalLeader>l   :Last<CR>
    nnoremap <silent><buffer> <LocalLeader>m1  :call <SID>ClojureMacroexpand(0)<CR>
    nnoremap <silent><buffer> <LocalLeader>me  :call <SID>ClojureMacroexpand(1)<CR>
    nnoremap <silent><buffer> <LocalLeader>mE  :call <SID>ClojureMacroexpand(2)<CR>
    nnoremap <silent><buffer> <LocalLeader>p   :call <SID>ClojurePprint('*1')<CR>
    nnoremap <silent><buffer> <LocalLeader>R   :Repl<CR>
    nnoremap <silent><buffer> <LocalLeader>r   :ReplHere<CR>
    nnoremap <silent><buffer> <LocalLeader>ss  :call fireplace#eval('(user.system/boot)')<CR>
    nnoremap <silent><buffer> <LocalLeader>sS  :call fireplace#eval('(user.system/stop)')<CR>
    nnoremap <silent><buffer> <LocalLeader>sr  :call fireplace#eval('(user.system/restart)')<CR>
    nnoremap <silent><buffer> <LocalLeader>si  :call <SID>ClojurePprint('@user.system/instance')<CR>
    nnoremap <silent><buffer> <LocalLeader>sl  :call <SID>ClojurePprint('@system/log')<CR>
    nnoremap <silent><buffer> <LocalLeader>sc  :call <SID>ClojurePprint('system/config')<CR>
    nnoremap <silent><buffer> <LocalLeader>sh  :Slamhound<CR>
    nnoremap <silent><buffer> <LocalLeader>st  :call <SID>ClojureStackTrace()<CR>
    nnoremap <silent><buffer> <LocalLeader>tr  :call fireplace#eval('(user/toggle-warn-on-reflection!)')<CR>
    nnoremap <silent><buffer> <LocalLeader>ts  :call <SID>ClojureTypeScaffold()<CR>
    nnoremap <silent><buffer> <LocalLeader>tt  :call <SID>ClojureRunTests(0)<CR>
    nnoremap <silent><buffer> <LocalLeader>tT  :call <SID>ClojureRunTests(1)<CR>
    nnoremap <silent><buffer> <LocalLeader>tv  :call fireplace#eval('(user/toggle-schema-validation!)')<CR>
    nnoremap <silent><buffer> <LocalLeader>tw  :call fireplace#eval('(user/toggle-warnings! true)')<CR>
    nnoremap <silent><buffer> <LocalLeader>tW  :call fireplace#eval('(user/toggle-warnings! false)')<CR>
    nnoremap <silent><buffer> <LocalLeader>u   :call fireplace#eval('(load-file "' . expand('~/.lein/user.clj') . '")')<CR>
endfunction

function! s:ClojurePprint(expr)
    silent call fireplace#eval('(do (clojure.pprint/pprint (do ' . a:expr . ')) ' . a:expr . ')')
    Last
    normal! yG
    pclose
    Sscratch
    setfiletype clojure
    execute "normal! gg\"_dGVPG\"_dd"
    wincmd L
endfunction

function! s:ClojureStackTrace()
    silent call fireplace#eval('(clojure.stacktrace/e)')
    Last
    wincmd L
endfunction

function! s:ClojureCheatSheet(pattern)
    if empty(a:pattern) | return | endif

    let file = fireplace#evalparse('(user/write-cheat-sheet! #"' . escape(a:pattern, '"') . '")')

    if empty(file)
        redraw! " Clear command line
        echo "No matching namespaces."
    else
        execute 'vsplit ' . file . ' | wincmd L'
    endif
endfunction

function! s:ClojureMacroexpand(once)
    let reg_save = @m
    let expand = ['macroexpand-1', 'macroexpand', 'clojure.walk/macroexpand-all'][a:once]
    execute "normal \"my\<Plug>(sexp_outer_list)"
    call s:ClojurePprint('(' . expand . ' (quote ' . @m . '))')
    wincmd L
    let @m = reg_save
endfunction

function! s:ClojureRunTests(all)
    if a:all
        Require!
        call fireplace#eval('(clojure.test/run-all-tests)')
    else
        call fireplace#eval('(user/run-tests-for-current-ns)')
    endif
endfunction

function! s:ClojureTypeScaffold()
    try
        let reg_save = [@e, @r]
        execute "normal \"ey\<Plug>(sexp_inner_element)"
        redir @r
        call fireplace#eval('(println (user/object-scaffold ' . @e . '))')
    finally
        redir END
        Sscratch
        wincmd L
        setfiletype clojure
        normal! gg"_dG"rPdd
        let [@e, @r] = reg_save
    endtry
endfunction

command! -nargs=? -complete=shellcmd -bar Screen call <SID>Screen(<q-args>) "{{{1
function! s:Screen(command)
    let map = {
        \ 'ruby'       : 'irb',
        \ 'clojure'    : 'lein REPL',
        \ 'python'     : 'python',
        \ 'scheme'     : 'scheme',
        \ 'haskell'    : 'ghci',
        \ 'javascript' : 'node'
        \ }
    let cmd = empty(a:command) ? (has_key(map, &filetype) ? map[&filetype] : '') : a:command
    execute 'ScreenShell ' . cmd
endfunction

command! -bar OrgBufferSetup call <SID>OrgBufferSetup() "{{{1
function! s:OrgBufferSetup()
    SetWhitespace 2 8
    setlocal foldlevel=0

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
function! s:Open(word)
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
function! s:Qfdo(expr)
    " Run a command over all lines in the quickfix buffer
    let qflist = getqflist()
    for item in qflist
        execute item['bufnr'] . 'buffer!'
        execute item['lnum'] . a:expr
    endfor
endfunction

command! -bar ToggleMinorWindows call <SID>ToggleMinorWindows() "{{{1
function! s:ToggleMinorWindows()
    if empty(filter(map(tabpagebuflist(), 'getbufvar(v:val, "&buftype")'), 'v:val == "quickfix"'))
        try
            cwindow | topleft lwindow
        catch /./
            cclose | lclose | pclose
        endtry
    else
        cclose | lclose | pclose
    endif
endfunction

command! -bar UniteOpen call fugitive#detect('.') | execute 'Unite -no-split ' . (exists('b:git_dir') ? 'git_cached git_untracked' : 'file')

command! -nargs=+ -complete=file -bar TabOpen call <SID>TabOpen(<f-args>) "{{{1
function! s:TabOpen(file, ...)
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
function! s:Tabmove(n)
    if version >= 703 && has('patch591')
        execute 'tabmove ' . printf('%+d', a:n)
    else
        let nr = a:n > 0 ? tabpagenr() + a:n - 1 : tabpagenr() - a:n - 3
        execute 'tabmove ' . (nr < 0 ? 0 : nr)
    endif
endfunction

command! -bar RunCurrentMiniTestCase call <SID>RunCurrentMiniTestCase() "{{{1
" Run a single MiniTest::Spec test case
function! s:RunCurrentMiniTestCase()
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
    execute 'Sh ruby % --name /test.*' . name . '/ | $PAGER'
endfunction

command! -bar MapReadlineUnicodeBindings call <SID>MapReadlineUnicodeBindings() "{{{1
function! s:MapReadlineUnicodeBindings()
    let inputrc = expand('~/.inputrc.d/utf-8')
    if filereadable(inputrc)
        for line in readfile(inputrc)
            if line[0] == '"'
                " Example: "\el": "λ"
                let key  = line[3]
                let char = line[8 : len(line) - 2]

                " By convention, we'll always map as Meta-.
                execute 'noremap! <Esc>' . key . ' ' . char
            endif
        endfor
    endif
endfunction

command! -bar CapturePane call <SID>CapturePane() "{{{1
function! s:CapturePane()
    " Tmux-esque capture-pane
    let buf = bufnr('%')
    let tab = len(tabpagebuflist()) > 1
    wincmd q
    execute 'normal! ' . (tab ? 'gT' : 'gt')
    execute buf . 'sbuffer'
    wincmd L
endfunction

command! -nargs=+ -complete=command -bar Capture call <SID>Capture(<q-args>) "{{{1
command! CaptureMaps
    \ execute 'Capture verbose map \| silent! verbose map!' |
    \ :%! ruby -Eutf-8 -e 'puts $stdin.read.chars.map { |c| c.unpack("U").pack "U" rescue "UTF-8-ERROR" }.join.gsub(/\n\t/, " \" ")'
" Redirect output of given commands into a scratch buffer
function! s:Capture(cmd)
    try
        let reg_save = @r
        redir @r
        execute 'silent! ' . a:cmd
    finally
        redir END
        new | setlocal buftype=nofile filetype=vim | normal! "rp
        execute "normal! d/\\v^\\s*\\S\<CR>"
        let @r = reg_save
    endtry
endfunction

command! -nargs=* -complete=file -bang -bar Org call <SID>Org('<bang>', <f-args>) "{{{1
function! s:Org(bang, ...)
    let tab = empty(a:bang) ? 'tab' : ''

    if a:0
        for f in a:000
            execute tab . 'edit ' . join([g:org_home, f . '.org'], '/')
            execute 'lcd ' . g:org_home
        endfor
    else
        if empty(a:bang) | tabnew | endif
        execute 'lcd ' . g:org_home | Unite -no-split git_cached git_untracked
    endif
endfunction

command! -nargs=1 -bar Speak call system('speak ' . shellescape(<q-args>))

command! -bar -range Interleave
    \ '<,'>! ruby -e 'l = $stdin.read.lines; puts l.take(l.count/2).zip(l.drop l.count/2).join'

" http://vim.wikia.com/wiki/Xterm256_color_names_for_console_Vim
command! -bar Hitest
    \ 45vnew |
    \ source $VIMRUNTIME/syntax/hitest.vim |
    \ setlocal synmaxcol=5000 nocursorline nocursorcolumn

function! CwordOrSel(...) " {{{1
    try
        let reg_save = @v
        if a:0 && a:1
            normal! gv"vy
            return @v
        else
            return expand('<cword>')
        endif
    finally
        let @v = reg_save
    endtry
endfunction

" Modify selected text using combining diacritics
" https://vim.wikia.com/wiki/Create_underlines,_overlines,_and_strikethroughs_using_combining_characters
command! -range -nargs=0 Overline        call s:CombineSelection(<line1>, <line2>, '0305')
command! -range -nargs=0 Underline       call s:CombineSelection(<line1>, <line2>, '0332')
command! -range -nargs=0 DoubleUnderline call s:CombineSelection(<line1>, <line2>, '0333')
command! -range -nargs=0 Strikethrough   call s:CombineSelection(<line1>, <line2>, '0336')

function! s:CombineSelection(line1, line2, cp)
  execute 'let char = "\u'.a:cp.'"'
  execute a:line1.','.a:line2.'s/\%V[^[:cntrl:]]/&'.char.'/ge'
endfunction
