""" Library of commands

command! -nargs=+ -complete=shellcmd Sh call system(<q-args>)

function! MkdirIfNotExists(dir)
	let dir = expand(a:dir)
	if !isdirectory(dir)
		call mkdir(dir, 'p', 0700)
	endif
endfunction

command! -bar Makesession call <SID>Makesession()
function! s:Makesession()
	" Use $PWD instead of getcwd() to avoid window-local cwd
	let dir = '~/.cache/vim/session' . $PWD
	call MkdirIfNotExists(dir)
	execute 'mksession! ' . fnameescape(dir) . '/Session.vim'
endfunction

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
		let paropts = a:0 == 2 ? a:2 : 'heq'
		execute 'set' . local . ' textwidth=' . a:1
		execute 'set' . local . ' formatprg=par\ ' . paropts . '\ ' . a:1
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
		setlocal formatoptions+=t formatoptions+=a formatoptions+=w
	else
		setlocal formatoptions-=t formatoptions-=a formatoptions-=w
	endif
endfunction

command! -bang -bar SetIskeyword call <SID>SetIskeyword('<bang>') "{{{1
function! s:SetIskeyword(bang)
	let nonspaces = '@,1-31,33-127'
	if empty(a:bang)
		setlocal iskeyword?
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
		setlocal diff?
	elseif &diff
		windo if expand('%:t') !=# 'index' && &buftype !~# '\vquickfix|help' | diffoff | endif
	else
		windo if expand('%:t') !=# 'index' && &buftype !~# '\vquickfix|help' | diffthis | endif
	endif
endfunction

command! -bang -bar SetVerbose call <SID>SetVerbose('<bang>') "{{{1
function! s:SetVerbose(bang)
	let enable = !exists('g:__SetVerbose__')

	if !empty(a:bang)
		call writefile([], '/tmp/verbose.vim')
	end

	if enable
		let g:__SetVerbose__ = 1
		set verbose=100 verbosefile=/tmp/verbose.vim
		echo '♫ BEGIN VERBOSE MODE ♫'
	else
		echo '♫ END VERBOSE MODE ♫'
		set verbose=0 verbosefile=
		unlet! g:__SetVerbose__
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

command! -bar Syntime call <SID>Syntime()
function! s:Syntime()
	if exists('g:__syntime_on__')
		unlet g:__syntime_on__
		syntime off
		Capture syntime report
	else
		let g:__syntime_on__ = 1
		syntime clear
		syntime on
	endif
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
	let words = ['TODO', 'FIXME', 'XXX']
	let arg = a:0 ? shellescape(expand(a:1), 1) : '.'

	" Fugitive detects Git repos for us
	if exists(':Ggrep')
		execute 'silent! Ggrep! --word-regexp "' . join(words,'|') . '" ' . (a:0 ? arg : shellescape(getcwd(), 1))
	elseif exists(':Ack')
		execute 'silent! Ack! --word-regexp "' . join(words,'\|') . '" ' . arg
	else
		execute 'silent! grep! --recursive --perl-regexp --word-regexp "' . join(words,'\|') . '" ' . arg
	endif
endfunction

command! -bar Maketags call <SID>Maketags() "{{{1
function! s:Maketags()
	if &filetype == 'go'
		let cmd = 'gotags -R -f .tags .'
	else
		let cmd = 'ctags -R'
	endif
	execute 'Sh (' . cmd . '; notify -? $?) >/dev/null 2>&1 &' | echo cmd
endfunction

command! -bar MailBufferSetup call <SID>MailBufferSetup()
function! s:MailBufferSetup()
	if !exists('b:mail_buffer_type')
		setlocal iskeyword+=-
		let b:mail_buffer_type = 'normal'
	endif

	if b:mail_buffer_type ==# 'normal'
		SetAutowrap 0
		set columns=80
		setlocal wrap
		let b:mail_buffer_type = 'technical'
	elseif b:mail_buffer_type ==# 'technical'
		SetAutowrap 1
		SetTextwidth 72
		setlocal nowrap
		let b:mail_buffer_type = 'normal'
	endif
endfunction

command! -bar CBufferSetup call <SID>CBufferSetup()
function! s:CBufferSetup()
	setlocal foldmethod=expr foldexpr=CFoldExpr(v:lnum)
	setlocal cinoptions=:0,N-s

	noremap <buffer> <LocalLeader>a :<C-u>CAlternate edit<CR>
	noremap <buffer> <LocalLeader>A :<C-u>CAlternate vsplit<CR>
	noremap <buffer> <LocalLeader>l :<C-u>ClangFormat<CR>
	noremap <buffer> <LocalLeader>L :!deheader -r %<CR>
endfunction

command! -bar -nargs=1 -complete=file ExecMakeprg call <SID>ExecMakeprg(<q-args>)
function! s:ExecMakeprg(makeprg)
	let makeprg_save = &makeprg
	let &l:makeprg = a:makeprg
	silent! make!
	let &l:makeprg = makeprg_save
endfunction

command! -bar Cpplint call <SID>ExecMakeprg('cpplint.py %')
command! -nargs=1 -complete=file -bar Yamllint call <SID>ExecMakeprg('yamllintwrapper --format parsable ' . <q-args>)

command! -bar ClangFormat call <SID>ClangFormat(expand('%:p'), 1)
function! s:ClangFormat(path, inplace)
	let cmd = 'clang-format-wrapper -- ' . shellescape(a:path)
	if a:inplace
		let cmd .= ' -i'
	endif
	call system(cmd)
	edit
endfunction

command! -nargs=1 -bar CAlternate call <SID>CAlternate(<f-args>)
function! s:CAlternate(cmd)
	if index(['c', 'cpp', 'cc'], expand('%:e')) > -1
		execute a:cmd . ' ' . expand('%:r') . '.h'
	else
		let root = expand('%:r')
		if filereadable(root . '.cc')
			execute a:cmd . ' ' . root . '.cc'
		elseif filereadable(root . '.cpp')
			execute a:cmd . ' ' . root . '.cpp'
		elseif filereadable(root . '.c')
			execute a:cmd . ' ' . root . '.c'
		endif
	endif
endfunction

function! FoldText(lnum)
	return repeat(' ', indent(a:lnum)) . substitute(getline(a:lnum), '\v^\s*', '', '')
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

function! AsmFoldExpr(lnum) "{{{1
	let line = getline(a:lnum)
	if line =~# '\v^\w\S*:'
		return '>2'
	elseif line =~# '\v^(section|segment)'
		return '>1'
	elseif line[:1] =~# '\v^;;'
		return '1'
	elseif getline(a:lnum - 1) =~ "\v^\s*ret"
		return '0'
	else
		return '='
	endif
endfunction

function! DiffFoldExpr(lnum) "{{{1
	let line = getline(a:lnum)
	if line =~# '\v^(commit|diff)>'
		return '>1'
	elseif getline(a:lnum - 3) =~# '\v^-- ' || line =~# '\v^Only in '
		return '0'
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
	elseif line[0] ==# ';'
		return '>1'
	else
		return '='
	endif
endfunction

command! -bar RainbowParens call <SID>RainbowParens()
function! s:RainbowParens()
	" Rainbow parens
	call rainbow_parentheses#load(0)
	call rainbow_parentheses#load(1)
	call rainbow_parentheses#load(2)
	call rainbow_parentheses#activate()
endfunction

command! -bar LispBufferSetup call <SID>LispBufferSetup() "{{{1
function! s:LispBufferSetup()
	let b:loaded_delimitMate = 1
	SetWhitespace 2 8
	setlocal expandtab foldmethod=expr foldexpr=LispFoldExpr(v:lnum)

	noremap  <silent><buffer> <4-CR>          A<Space>;<Space>
	noremap! <silent><buffer> <4-CR>          <C-\><C-o>A<Space>;<Space>
	nnoremap <silent><buffer> <LocalLeader>tl :<C-u>call <SID>ToggleLispwords(expand('<cword>'))<CR>
endfunction

command! -bar TimLBufferSetup call <SID>TimLBufferSetup() "{{{1
function! s:TimLBufferSetup()
	LispBufferSetup

	nmap     <silent><buffer> <Leader><Leader> cp<Plug>(sexp_outer_list)``
	imap     <silent><buffer> <Leader><Leader> <C-\><C-o><C-\><C-n><Leader><Leader>

	nmap     <silent><buffer> <Leader>X        cp<Plug>(sexp_outer_top_list)``
	imap     <silent><buffer> <Leader>X        <C-\><C-o><C-\><C-n><Leader>X

	nmap     <silent><buffer> <Leader>x        cp<Plug>(sexp_inner_element)``
	imap     <silent><buffer> <Leader>x        <C-\><C-o><C-\><C-n><Leader>x
endfunction

command! -bar ClojureBufferSetup call <SID>ClojureBufferSetup() "{{{1
function! s:ClojureBufferSetup()
	LispBufferSetup

	nmap     <silent><buffer> K                <Plug>FireplaceK

	vmap     <silent><buffer> <Leader><Leader> <Plug>FireplacePrint
	nmap     <silent><buffer> <Leader><Leader> <Plug>FireplacePrint<Plug>(sexp_outer_list)``
	imap     <silent><buffer> <Leader><Leader> <C-\><C-o><C-\><C-n><Leader><Leader>

	nmap     <silent><buffer> <Leader>X        <Plug>FireplacePrint<Plug>(sexp_outer_top_list)``
	imap     <silent><buffer> <Leader>X        <C-\><C-o><C-\><C-n><Leader>X

	nmap     <silent><buffer> <Leader>x        <Plug>FireplacePrint<Plug>(sexp_inner_element)``
	imap     <silent><buffer> <Leader>x        <C-\><C-o><C-\><C-n><Leader>x

	nnoremap <silent><buffer> <Leader>r        :Require \| ClojureHighlightReferences<CR>
	nnoremap <silent><buffer> <Leader>R        :call fireplace#session_eval('(guns.repl/refresh)') \| ClojureHighlightReferences<CR>
	nnoremap <silent><buffer> <Leader><M-r>    :call fireplace#session_eval('(guns.repl/refresh-all)') \| ClojureHighlightReferences<CR>
	nnoremap <silent><buffer> <Leader><M-R>    :Require! clojure.tools.analyzer.jvm<CR>
	nnoremap <silent><buffer> <LocalLeader>co  :execute 'Connect nrepl://localhost:' . readfile('.nrepl-port')[0]<CR>
	nnoremap <silent><buffer> <LocalLeader>cp  :Capture call fireplace#session_eval('(guns.repl/print-classpath!)') \| setfiletype plain<CR>
	nnoremap <silent><buffer> <LocalLeader>cs  :call <SID>ClojureCheatSheet('\A\Q' . fireplace#ns() . '\E\z')<CR>
	nnoremap <silent><buffer> <LocalLeader>cS  :call <SID>ClojureCheatSheet(input('Namespace filter: '))<CR>
	nnoremap <silent><buffer> <LocalLeader>CS  :call <SID>ClojureCheatSheet('.')<CR>
	nnoremap <silent><buffer> <LocalLeader>e   :call <SID>ClojurePprint('*e')<CR>
	nnoremap <silent><buffer> <LocalLeader>i   :call fireplace#session_eval('(do (load-file "' . expand('~/.local/lib/clojure/guns/src/guns/repl.clj') . '") (guns.repl/init!))')<CR>
	nnoremap <silent><buffer> <LocalLeader>ja  :Capture call fireplace#session_eval('(guns.repl/print-jvm-args!)') \| setfiletype plain<CR>
	nnoremap <silent><buffer> <LocalLeader>l   :Last<CR>
	nnoremap <silent><buffer> <LocalLeader>m1  :call <SID>ClojureMacroexpand(0)<CR>
	nnoremap <silent><buffer> <LocalLeader>me  :call <SID>ClojureMacroexpand(1)<CR>
	nnoremap <silent><buffer> <LocalLeader>mE  :call <SID>ClojureMacroexpand(2)<CR>
	nnoremap <silent><buffer> <LocalLeader>ns  :call <SID>ClojureViewNsGraph(input('Constraints: ', ":dependents '" . fireplace#ns() . ' '))<CR>
	nnoremap <silent><buffer> <LocalLeader>nS  :call <SID>ClojureViewNsGraph(input('Constraints: ', ":dependencies '" . fireplace#ns() . ' '))<CR>
	nnoremap <silent><buffer> <LocalLeader>p   :call <SID>ClojurePprint('*1')<CR>
	nnoremap <silent><buffer> <LocalLeader>R   :Repl<CR>
	nnoremap <silent><buffer> <LocalLeader>r   :ReplHere<CR>
	nnoremap <silent><buffer> <LocalLeader>od  :call <SID>ClojureElementRedir('guns.repl/disassemble')<CR>
	nnoremap <silent><buffer> <LocalLeader>or  :call <SID>ClojureElementRedir('(comp clojure.pprint/pprint guns.repl/reflect)')<CR>
	nnoremap <silent><buffer> <LocalLeader>os  :call <SID>ClojureElementRedir('(comp println guns.repl/object-scaffold)')<CR>
	nnoremap <silent><buffer> <LocalLeader>ss  :call fireplace#session_eval('(guns.system/boot)')<CR>
	nnoremap <silent><buffer> <LocalLeader>sS  :call fireplace#session_eval('(guns.system/stop)')<CR>
	nnoremap <silent><buffer> <LocalLeader>sr  :call fireplace#session_eval('(guns.system/restart)')<CR>
	nnoremap <silent><buffer> <LocalLeader>si  :call <SID>ClojurePprint('@guns.system/instance')<CR>
	nnoremap <silent><buffer> <LocalLeader>sl  :call <SID>ClojurePprint('@system/log')<CR>
	nnoremap <silent><buffer> <LocalLeader>sc  :call <SID>ClojurePprint('system/config')<CR>
	nnoremap <silent><buffer> <LocalLeader>sp  :call <SID>ClojureSetPrintLength(input('Max print length: '))<CR>
	nnoremap <silent><buffer> <LocalLeader>sh  :Slamhound<CR>
	nnoremap <silent><buffer> <LocalLeader>st  :call <SID>ClojureStackTrace()<CR>
	nnoremap <silent><buffer> <LocalLeader>tf  :call <SID>ClojureFilterForm("(guns.repl/thread-form '-> %s)")<CR>
	nnoremap <silent><buffer> <LocalLeader>tF  :call <SID>ClojureFilterForm("(guns.repl/thread-form '->> %s)")<CR>
	nnoremap <silent><buffer> <LocalLeader>TF  :call <SID>ClojureFilterForm("(guns.repl/unthread-form %s)")<CR>
	nnoremap <silent><buffer> <LocalLeader>tr  :call fireplace#session_eval('(guns.repl/toggle-warn-on-reflection!)')<CR>
	nnoremap <silent><buffer> <LocalLeader>tt  :call <SID>ClojureRunTests()<CR>
	nnoremap <silent><buffer> <LocalLeader>tT  :call <SID>ClojureRunTests(input('Test filter: '))<CR>
	nnoremap <silent><buffer> <LocalLeader>TT  :call <SID>ClojureRunAllTests()<CR>
	nnoremap <silent><buffer> <LocalLeader>tv  :call fireplace#session_eval('(guns.repl/toggle-schema-validation!)')<CR>
	nnoremap <silent><buffer> <LocalLeader>tw  :call fireplace#session_eval('(guns.repl/toggle-warnings! true)')<CR>
	nnoremap <silent><buffer> <LocalLeader>tW  :call fireplace#session_eval('(guns.repl/toggle-warnings! false)')<CR>
	nnoremap <silent><buffer> <LocalLeader>wc  :call fireplace#session_eval("(do (require 'com.sungpae.warn-closeable) (com.sungpae.warn-closeable/warn-closeable! [*ns*]))")<CR>
	nnoremap <silent><buffer> <LocalLeader>WC  :call fireplace#session_eval("(do (require 'com.sungpae.warn-closeable) (com.sungpae.warn-closeable/warn-closeable!))")<CR>
endfunction

function! s:ClojurePprint(expr)
	silent call fireplace#session_eval('(do (clojure.pprint/pprint (do ' . a:expr . ')) ' . a:expr . ')')
	Last
	normal! yG
	pclose
	Sscratch
	setfiletype clojure
	execute "normal! gg\"_dGVPG\"_dd"
	wincmd L
endfunction

function! s:ClojureStackTrace()
	silent call fireplace#session_eval('(clojure.stacktrace/e)')
	Last
	wincmd L
endfunction

function! s:ClojureCheatSheet(pattern)
	if empty(a:pattern) | return | endif

	let file = fireplace#evalparse('(guns.repl/write-cheat-sheet! #"' . escape(a:pattern, '"') . '")')

	if empty(file)
		redraw! " Clear command line
		echo "No matching namespaces."
	else
		execute 'vsplit ' . escape(file, '%') . ' | wincmd L'
	endif
endfunction

function! s:ClojureFilterForm(fmt)
	execute "normal \"fy\<Plug>(sexp_outer_list)"
	let @f = fireplace#evalparse(printf(a:fmt, '"' . escape(@f, '\"') . '"'))
	execute "normal gv\"fp\<Plug>(sexp_indent)"
endfunction

function! s:ClojureMacroexpand(once)
	let reg_save = @m
	let expand = ['macroexpand-1', 'macroexpand', 'clojure.walk/macroexpand-all'][a:once]
	execute "normal \"my\<Plug>(sexp_outer_list)"
	call s:ClojurePprint('(' . expand . ' (quote ' . @m . '))')
	wincmd L
	let @m = reg_save
endfunction

function! s:ClojureViewNsGraph(constraints)
	if len(a:constraints)
		call fireplace#session_eval('(guns.repl/view-ns-graph ' . a:constraints . ')')
	endif
endfunction

function! s:ClojureRunTests(...)
	if a:0
		if empty(a:1) | return | endif
		let b:clojure_test_filter = a:1
	elseif !exists('b:clojure_test_filter')
		let b:clojure_test_filter = '.'
	endif

	if b:clojure_test_filter == '.'
		call fireplace#session_eval('(guns.repl/run-tests-for-current-ns)')
	else
		echo "\r"
		call fireplace#session_eval('(guns.repl/run-tests-for-current-ns #"' . escape(b:clojure_test_filter, '"') . '")')
	endif
endfunction

function! s:ClojureRunAllTests()
	Require!
	return fireplace#session_eval('(clojure.test/run-all-tests)')
endfunction

function! s:ClojureElementRedir(fn)
	try
		let reg_save = [@e, @r]
		execute "normal \"ey\<Plug>(sexp_inner_element)"
		redir @r
		silent call fireplace#session_eval('(' . a:fn . ' ' . @e . ')')
	finally
		redir END
		Sscratch
		wincmd L
		setfiletype clojure
		normal! gg"_dG"rPdd
		let [@e, @r] = reg_save
	endtry
endfunction

function! s:ClojureSetPrintLength(input)
	if empty(a:input) | return | endif

	let args = split(a:input)
	if len(args) == 2
		let [length, depth] = args
	else
		let length = args[0]
		let depth = length
	endif

	redraw

	echo fireplace#evalparse('(do (guns.repl/set-print-length! ' . +length . ' ' . +depth . ')'
	                         \ . '[*print-length* *print-level*])')
endfunction

function! s:ToggleLispwords(word)
	" Strip leading namespace qualifiers and macro characters from symbol
	let word = substitute(a:word, "\\v%(.*/|[#'`~@^,]*)(.*)", '\1', '')

	if &lispwords =~# '\V\<' . word . '\>'
		execute 'setlocal lispwords-=' . word
		echo "Removed " . word . " from lispwords."
	else
		execute 'setlocal lispwords+=' . word
		echo "Added " . word . " to lispwords."
	endif
endfunction

command! -nargs=? -complete=shellcmd -bar Screen call <SID>Screen(<q-args>) "{{{1
function! s:Screen(command)
	let map = {
		\ 'clojure':    'lein repl',
		\ 'go':         'gomacro',
		\ 'haskell':    'ghci',
		\ 'j':          'J',
		\ 'javascript': 'node',
		\ 'python':     'python',
		\ 'ruby':       'irb',
		\ 'scheme':     'scheme',
		\ }
	let cmd = empty(a:command) ? (has_key(map, &filetype) ? map[&filetype] : '') : a:command
	execute 'ScreenShell ' . cmd
endfunction

command! -bar RubyBufferSetup call <SID>RubyBufferSetup()
function! s:RubyBufferSetup()
	SetWhitespace 2 8
	setlocal expandtab makeprg=rake iskeyword+=?,!

	noremap! <buffer> <C-l>           <Space>=><Space>
	noremap  <buffer> <LocalLeader>a  :<C-u>A<CR>
	noremap  <buffer> <LocalLeader>A  :<C-u>R<CR>
	noremap  <buffer> <LocalLeader>ec :<C-u>Econtroller<CR>
	noremap  <buffer> <LocalLeader>ee :<C-u>Eenvironment<CR>
	noremap  <buffer> <LocalLeader>ef :<C-u>Efixtures<CR>
	noremap  <buffer> <LocalLeader>eF :<C-u>Efunctionaltest<CR>
	noremap  <buffer> <LocalLeader>eh :<C-u>Ehelper<CR>
	noremap  <buffer> <LocalLeader>ei :<C-u>Einitializer<CR>
	noremap  <buffer> <LocalLeader>eI :<C-u>Eintegrationtest<CR>
	noremap  <buffer> <LocalLeader>ej :<C-u>Ejavascript<CR>
	noremap  <buffer> <LocalLeader>el :<C-u>Elayout<CR>
	noremap  <buffer> <LocalLeader>eL :<C-u>Elib<CR>
	noremap  <buffer> <LocalLeader>em :<C-u>Emodel<CR>
	noremap  <buffer> <LocalLeader>eM :<C-u>Emigration<CR>
	noremap  <buffer> <LocalLeader>es :<C-u>Eschema<CR>
	noremap  <buffer> <LocalLeader>eS :<C-u>Espec<CR>
	noremap  <buffer> <LocalLeader>et :<C-u>Etask<CR>
	noremap  <buffer> <LocalLeader>eu :<C-u>Eunittest<CR>
	noremap  <buffer> <LocalLeader>ev :<C-u>Eview<CR>
	noremap  <buffer> <LocalLeader>l  :<C-u>RuboCop --fail-level=warning --display-only-fail-level-offenses<CR>
	noremap  <buffer> <LocalLeader>L  :<C-u>Clog<CR>
	noremap  <buffer> <LocalLeader>p  :<C-u>Preview<CR>
	noremap  <buffer> <LocalLeader>t  :<C-u>Runner<CR>
	nnoremap <buffer> <localleader>r  viw:RRenameLocalVariable<CR>
	vnoremap <buffer> <localleader>r  :RRenameLocalVariable<CR>
	nnoremap <buffer> <localleader>R  viw:RRenameInstanceVariable<CR>
	vnoremap <buffer> <localleader>R  :RRenameInstanceVariable<CR>
endfunction

command! -bar -bang StandardJS call <SID>StandardJS('<bang>')
function! s:StandardJS(bang)
	if !executable('standard') | return | endif

	let args = ''

	if !empty(a:bang) || getline('$') =~# 'standardjs'
		let args .= ' --verbose --fix'
	endif

	setlocal autoread
	call <SID>ExecMakeprg('standard ' . args . ' %')
endfunction

command! -bar JavaScriptBufferSetup call <SID>JavaScriptBufferSetup()
function! s:JavaScriptBufferSetup()
	SetWhitespace 2
	setlocal expandtab

	noremap  <buffer> <LocalLeader>l :<C-u>StandardJS!<CR>
	inoremap <buffer> <C-l>          <Space>=><Space>
	noremap  <buffer> <4-CR>         A;<Esc>
	inoremap <buffer> <4-CR>         <C-\><C-o>A;
	inoremap <buffer> <M-CR>         keyvalue<C-r>=UltiSnips#ExpandSnippet()<CR>
	noremap  <buffer> <M-CR>         akeyvalue<C-r>=UltiSnips#ExpandSnippet()<CR>
endfunction

command! -bar OrgBufferSetup call <SID>OrgBufferSetup() "{{{1
function! s:OrgBufferSetup()
	SetWhitespace 2 8

	map  <silent> <buffer> <4-m> :<C-u>call <SID>UpdateWorklog()<CR>

	map  <silent> <buffer> <4-[> <Plug>OrgPromoteHeadingNormal
	imap <silent> <buffer> <4-[> <C-\><C-o><Plug>OrgPromoteHeadingNormal
	map  <silent> <buffer> <4-]> <Plug>OrgDemoteHeadingNormal
	imap <silent> <buffer> <4-]> <C-\><C-o><Plug>OrgDemoteHeadingNormal

	map  <silent> <buffer> <M-j> <Plug>OrgMoveSubtreeDownward
	imap <silent> <buffer> <M-j> <C-\><C-o><Plug>OrgMoveSubtreeDownward
	map  <silent> <buffer> <M-k> <Plug>OrgMoveSubtreeUpward
	imap <silent> <buffer> <M-k> <C-\><C-o><Plug>OrgMoveSubtreeUpward

	map  <silent> <buffer> <M-h> <Plug>OrgPromoteSubtreeNormal
	imap <silent> <buffer> <M-h> <C-\><C-o><Plug>OrgPromoteSubtreeNormal
	map  <silent> <buffer> <M-l> <Plug>OrgDemoteSubtreeNormal
	imap <silent> <buffer> <M-l> <C-\><C-o><Plug>OrgDemoteSubtreeNormal

	map  <silent> <buffer> <4-CR> <Plug>OrgNewHeadingBelowNormal
	imap <silent> <buffer> <4-CR> <C-\><C-o><Plug>OrgNewHeadingBelowNormal
	map  <silent> <buffer> <M-CR> <Plug>OrgNewHeadingBelowNormal<C-\><C-o><Plug>OrgDemoteHeadingNormal<End>
	imap <silent> <buffer> <M-CR> <C-\><C-n><M-CR>

	" Please don't remap core keybindings!
	silent! iunmap <buffer> <C-d>
	silent! iunmap <buffer> <C-t>
endfunction

function! s:UpdateWorklog()
	if has('ruby')
ruby << EORUBY
		# -*- encoding: utf-8 -*-

		require 'time'

		entries = []
		minutes = 0

		$curbuf.count.downto(1).each do |n|
			if $curbuf[n] =~ /\A([* ]*)(\d\d:\d\d:\d\d)\s*-\s*(\d\d:\d\d:\d\d)(?: (?:=>|→) \d+m\s*\z)?/
				min = ((Time.parse($3) - Time.parse($2))/60.0).round
				$curbuf[n] = "#{$1}#{$2} - #{$3} → #{min}m"
				minutes += min
			end

			if $curbuf[n] =~ /\A\*\s*(\d{4}-\d{2}-\d{2})(?: (?:=>|→) TOTAL: \d+m\s*\z)?/
				$curbuf[n] = "* #{$1} → TOTAL: #{minutes}m"
				entries << [$1, minutes]
				minutes = 0
			end
		end

		lines = []
		date_w = entries.map { |e| e[0].length }.max
		sum = entries.reduce(0) { |s, e| s + e[1] }
		min_w = sum.to_s.size
		fmt = "%-#{date_w}s │ %#{min_w}dm"

		lines << ("─" * (date_w+1) << "┬" << "─" * (min_w+2))
		entries.reverse.each { |e| lines << fmt % e }
		lines << ("─" * (date_w+1) << "┼" << "─" * (min_w+2))
		lines << (" " * (date_w-5) << "TOTAL │ #{sum}m")

		c_row, c_col = $curwin.cursor
		n = 0

		if $curbuf[1] =~ /\A─+┬─+/
			while $curbuf[1] =~ /[─│]/
				$curbuf.delete 1
				n += 1
			end
		end

		lines.each_with_index { |l, i| $curbuf.append i, l }

		$curwin.cursor = [c_row - n + lines.count, c_col]
EORUBY
	endif
endfunction

command! -bar RustBufferSetup call <SID>RustBufferSetup()
function! s:RustBufferSetup()
	noremap! <buffer> <C-l>      <Space>=><Space>
	nmap     <buffer> <C-]>      <Plug>(rust-def)
	nmap     <buffer> <C-w><C-]> <Plug>(rust-def-vertical)
	nmap     <buffer> K          <Plug>(rust-doc)
endfunction

command! -bar GoBufferSetup call <SID>GoBufferSetup()
function! s:GoBufferSetup()
	set laststatus=2
	setlocal statusline=%f\ %{go#statusline#Show()}%=%-15(%l,%c%)%P

	noremap! <buffer> <C-h>          <-
	noremap! <buffer> <C-l>          <Space>:=<Space>
	nmap     <buffer> <C-]>          <Plug>(go-def)
	nmap     <buffer> <C-w><C-]>     <Plug>(go-def-vertical)
	nmap     <buffer> [C             <Plug>(go-callees)
	nmap     <buffer> ]C             <Plug>(go-callers)
	nmap     <buffer> [d             <Plug>(go-info)
	nmap     <buffer> ]d             <Plug>(go-describe)
	nmap     <buffer> [e             <Plug>(go-iferr)
	nmap     <buffer> <LocalLeader>a <Plug>(go-alternate-edit)
	nmap     <buffer> <LocalLeader>A <Plug>(go-alternate-vertical)
	nmap     <buffer> <LocalLeader>b <Plug>(go-build)
	nmap     <buffer> <LocalLeader>c <Plug>(go-coverage-toggle)
	nmap     <buffer> <LocalLeader>C <Plug>(go-channelpeers)
	noremap  <buffer> <LocalLeader>d :<C-u>GoDoc<Space>
	noremap  <buffer> <LocalLeader>e :<C-u>GoErrCheck -abspath<CR>
	noremap  <buffer> <LocalLeader>E :<C-u>GoErrCheck -ignore=fmt:^$ -abspath -asserts -blank<CR>
	noremap  <buffer> <LocalLeader>f vaB:GoFreevars<CR>
	vnoremap <buffer> <LocalLeader>f :GoFreevars<CR>
	noremap  <buffer> <LocalLeader>F :<C-u>GoFillStruct<CR>
	noremap  <buffer> <LocalLeader>g :<C-u>GoGuruScope<Space>
	nmap     <buffer> <LocalLeader>G <Plug>(go-generate)
	nmap     <buffer> <LocalLeader>i <Plug>(go-install)
	nmap     <buffer> <LocalLeader>I <Plug>(go-implements)
	noremap  <buffer> <LocalLeader><M-i> :<C-u>GoImpl<Space>
	noremap  <buffer> <LocalLeader>k :<C-u>GoKeyify<CR>
	noremap  <buffer> <LocalLeader>l :<C-u>GoMetaLinter<CR>
	noremap  <buffer> <LocalLeader>L :<C-u>GoLint -min_confidence=0<CR>
	noremap  <buffer> <LocalLeader>o :<C-u>GoOptimizations<CR>
	noremap  <buffer> <LocalLeader>p :<C-u>GoPath<Space>
	nmap     <buffer> <LocalLeader>P <Plug>(go-pointsto)
	nmap     <buffer> <LocalLeader>r <Plug>(go-referrers)
	nmap     <buffer> <LocalLeader>R <Plug>(go-rename)
	nmap     <buffer> <LocalLeader>s <Plug>(go-callstack)
	noremap  <buffer> <LocalLeader>S :<C-u>GoAssemble<CR>
	nmap     <buffer> <LocalLeader>t <Plug>(go-test)
	nmap     <buffer> <LocalLeader>T <Plug>(go-test-func)
	noremap  <buffer> <LocalLeader><M-t> :<C-u>GoTest -race<CR>
	nmap     <buffer> <LocalLeader>v <Plug>(go-vet)
	noremap  <buffer> <LocalLeader>w :<C-u>GoWhicherrs<CR>
	noremap  <buffer> _d             :<C-u>GoDebugStart .<Space>
	noremap  <buffer> _t             :<C-u>GoDebugTest<Space>
	noremap  <buffer> _r             :<C-u>GoDebugRestart<CR>
	noremap  <buffer> _b             :<C-u>GoDebugBreakpoint<CR>
	noremap  <buffer> _c             :<C-u>GoDebugContinue<CR>
	noremap  <buffer> _n             :<C-u>GoDebugNext<CR>
	noremap  <buffer> _s             :<C-u>GoDebugStep<CR>
	noremap  <buffer> _S             :<C-u>GoDebugStepOut<CR>
	noremap  <buffer> _=             :<C-u>GoDebugSet<Space>
	noremap  <buffer> _p             :<C-u>GoDebugPrint<Space>
	noremap  <buffer> _x             :<C-u>GoDebugStop<CR>
endfunction

function! s:CompareQuickfix(p, q)
	let p = bufname(a:p['bufnr'])
	let q = bufname(a:q['bufnr'])
	return p > q ? 1 : (p < q ? -1 : (a:p['lnum'] > a:q['lnum'] ? 1 : -1))
endfunction

command! -bar GoOptimizations call <SID>GoOptimizations()
function! s:GoOptimizations()
	call <SID>ExecMakeprg('go build -gcflags=-m\ -d=ssa/check_bce ' . go#package#ImportPath())

	let visited = {}
	let qflist = getqflist()
	let newqflist = []
	for item in qflist
		let k = string(item)
		if !has_key(visited, k)
			let visited[k] = item
			call add(newqflist, item)
		endif
	endfor
	call setqflist(sort(newqflist, "s:CompareQuickfix"))
endfunction

command! -bar GoAssemble call <SID>GoAssemble()
function! s:GoAssemble()
	let cmd = stridx(expand('%'), '_test') > -1 ? 'test -run=✖' : 'build'
	let pkg = go#package#ImportPath()
	Sscratch
	setfiletype plain
	normal! gg"_dG
	execute '.!go ' . cmd . ' -gcflags=-S ' . pkg . ' 2>&1 | ruby -e "puts \$stdin.read.gsub(/\\(\#{Regexp.escape Dir.pwd}\\//, \%q{(})"'
	normal! gg
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

command! -nargs=? -complete=command Qfdo call <SID>Listdo(getqflist(), <q-args>) "{{{1
command! -nargs=? -complete=command Locdo call <SID>Listdo(getloclist(0), <q-args>) "{{{1
function! s:Listdo(list, expr)
	for item in a:list
		execute item['bufnr'] . 'buffer!'
		call cursor(item['lnum'], item['col'])
		execute a:expr
	endfor
endfunction

command! -nargs=* -bar Grepqflist   call <SID>Grepqflist(1, <q-args>)
command! -nargs=* -bar Removeqflist call <SID>Grepqflist(0, <q-args>)
function! s:Grepqflist(match, pat)
	call setqflist(filter(getqflist(), "bufname(v:val['bufnr']) . v:val['text'] " . (a:match ? '=~' : '!~') . " a:pat"))
	call setloclist(0, filter(getloclist(0), "bufname(v:val['bufnr']) . v:val['text'] " . (a:match ? '=~' : '!~') . " a:pat"))
endfunction

command! -bar ClearQuickfix call <SID>ClearQuickfix()
function! s:ClearQuickfix()
	if getwininfo(bufwinid('%'))[0]['loclist']
		call setloclist(0, []) | lclose
	else
		call setqflist([]) | cclose
	end
endfunction

command! -bar ToggleMinorWindows call <SID>ToggleMinorWindows() "{{{1
function! s:ToggleMinorWindows()
	if empty(filter(map(tabpagebuflist(), 'getbufvar(v:val, "&buftype")'), 'v:val == "quickfix"'))
		if !empty(getloclist(0))
			topleft lwindow | wincmd p
		endif
		if !empty(getqflist())
			copen | wincmd p
		endif
	else
		lclose | cclose | pclose
	endif
endfunction

command! -bar FuzzyOpen call fugitive#detect('.') | execute (exists('b:git_dir') ? 'FzfGFiles! --cached --others --exclude-standard' : 'FZF!')

command! -nargs=+ -complete=file -bar TabOpen call <SID>TabOpen(<f-args>) "{{{1
function! s:TabOpen(path)
	let path = substitute(a:path, '\v^(\~[^/]*)', '\=expand(submatch(1))', '')
	let path = substitute(path, '\v(\$\w+)', '\=expand(submatch(1))', 'g')
	let path = resolve(path)

	for t in range(tabpagenr('$'))
		for b in tabpagebuflist(t + 1)
			if path ==# expand('#' . b . ':p')
				execute ':' . (t + 1)     . 'tabnext'
				execute ':' . bufwinnr(b) . 'wincmd w'
				return
			endif
		endfor
	endfor

	execute 'tabedit ' . fnameescape(path)
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
	let only = len(tabpagebuflist()) == 1 " Only window in current tab?
	wincmd q
	if !only
		tabprevious
	endif
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
			if filereadable(f . '.org')
				execute tab . 'edit ' . f . '.org'
			else
				execute tab . 'edit ' . join([g:org_home, f . '.org'], '/')
				execute 'lcd ' . g:org_home
			endif
		endfor
	else
		if empty(a:bang) | tabnew | endif
		execute 'lcd ' . g:org_home | FZF!
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
			silent normal! gv"vy
			return @v
		else
			return expand('<cword>')
		endif
	finally
		let @v = reg_save
	endtry
endfunction

command! -bar -range AddNumbersInSelection call <SID>AddNumbersInSelection()
function! s:AddNumbersInSelection()
	let s = CwordOrSel(1)
ruby << EORUBY
	require 'bigdecimal'
	print VIM.evaluate('s').scan(/(?:[+-])?\d+(?:\.\d+)?/).reduce(0) { |Σ, n|
		Σ + BigDecimal(n)
	}.to_s('F')
EORUBY
endfunction

" Modify selected text using combining diacritics
" https://vim.wikia.com/wiki/Create_underlines,_overlines,_and_strikethroughs_using_combining_characters
command! -range -nargs=1 Combine         call s:CombineSelection(<line1>, <line1>, <q-args>)
command! -range -nargs=0 Overline        call s:CombineSelection(<line1>, <line2>, '0305')
command! -range -nargs=0 Underline       call s:CombineSelection(<line1>, <line2>, '0332')
command! -range -nargs=0 DoubleUnderline call s:CombineSelection(<line1>, <line2>, '0333')
command! -range -nargs=0 Strikethrough   call s:CombineSelection(<line1>, <line2>, '0336')
command! -range -nargs=0 Slashthrough    call s:CombineSelection(<line1>, <line2>, '0338')

function! s:CombineSelection(line1, line2, cp)
	execute 'let char = "\u'.a:cp.'"'
	execute a:line1.','.a:line2.'s/\%V[^[:cntrl:]]/&'.char.'/ge'
	normal! ``
endfunction

command! -bar ByteOffset echo <SID>ByteOffset()
function! s:ByteOffset()
	return line2byte(line('.')) + col('.') - 1
endfunction

command! -range=% -nargs=1 -bar F  call <SID>FilterLines(<line1>, <line2>, '-Pi', <q-args>)
command! -range=% -nargs=1 -bar FV call <SID>FilterLines(<line1>, <line2>, '-Piv', <q-args>)
function! s:FilterLines(line1, line2, grepopts, pattern)
	execute a:line1 . ',' . a:line2 . '!grep ' . shellescape(a:grepopts) . ' -- ' . shellescape(a:pattern)
endfunction
