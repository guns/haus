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
		execute 'setlocal formatoptions+=t formatoptions+=a formatoptions+=w'
	else
		execute 'setlocal formatoptions-=t formatoptions-=a formatoptions-=w'
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

command! -bar Ctags call <SID>Ctags() "{{{1
function! s:Ctags()
	if &filetype == 'javascript'
		let cmd = 'jsctags.js -f .jstags' . shellescape(expand('%'))
	elseif &filetype == 'go'
		let cmd = 'gotags -R -f .tags .'
	else
		let cmd = 'ctags -R'
	endif
	execute 'Sh (' . cmd . '; notify -? $?) >/dev/null 2>&1 &' | echo cmd
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
	if getline(a:lnum) =~# '\v^commit>'
		return '>1'
	elseif getline(a:lnum) =~# '\v^diff>'
		return '>2'
	elseif getline(a:lnum - 3) =~# '\v^-- ' ||
	     \ getline(a:lnum) =~# '\v^Only in '
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
		\ 'ruby'       : 'irb',
		\ 'clojure'    : 'lein REPL',
		\ 'python'     : 'python',
		\ 'scheme'     : 'scheme',
		\ 'haskell'    : 'ghci',
		\ 'javascript' : 'node',
		\ 'j'          : 'J'
		\ }
	let cmd = empty(a:command) ? (has_key(map, &filetype) ? map[&filetype] : '') : a:command
	execute 'ScreenShell ' . cmd
endfunction

command! -bar OrgBufferSetup call <SID>OrgBufferSetup() "{{{1
function! s:OrgBufferSetup()
	SetWhitespace 2 8

	nnoremap <silent> <buffer> <4-m> :<C-u>call <SID>AppendMinutesDelta()<CR>$:call search('\v\d+:\d+:\d+', 'W')<CR>
	map  <silent> <buffer> <4-M> :<C-u>call <SID>CalculateTotalMinutes()<CR>

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

if has('ruby')
	function! s:AppendMinutesDelta()
ruby << EORUBY
		require 'time'
		line = VIM::Buffer.current.line
		if not line.include? '=>'
			begin
				from, to = line.scan(/\d+:\d+:\d+/).take(2).map { |s| Time.parse s }
				VIM::Buffer.current.line = '%s => %sm' % [line, ((to - from)/60.0).round]
			rescue
			end
		end
EORUBY
	endfunction

	function! s:CalculateDailyMinutes()
		execute "normal v\<Plug>OrgAInnerTreeVisual" . '"my'
ruby << EORUBY
		line = VIM::Buffer.current.line
		if not line.include? '=>'
			buf = VIM.evaluate '@m'
			total = buf.scan(/ => (\d+)m/).flatten.map(&:to_i).reduce :+
			VIM::Buffer.current.line = '%s => TOTAL: %sm' % [line, total]
		end
EORUBY
	endfunction

	function! s:CalculateTotalInvoiceMinutes()
ruby << EORUBY
		buf = VIM::Buffer.current
		dates, minutes = [], []
		(1..buf.count).each do |i|
			if buf[i] =~ /\*\s*(.+) => TOTAL: (\d+)m/
				dates << $1
				minutes << $2
			end
		end
		lines = []
		dw = dates.map(&:size).max
		sum = minutes.map(&:to_i).reduce(&:+)
		mw = sum.to_s.size
		lines << ("─" * (dw+1) << "┬" << "─" * (mw+2))
		fmt = "%-#{dw}s │ %#{mw}dm"
		dates.zip(minutes).each do |dm|
			lines << fmt % dm
		end
		lines << ("─" * (dw+1) << "┼" << "─" * (mw+2))
		lines << (" " * (dw-5) << "TOTAL │ #{sum}m")
		lines.each_with_index do |l, i|
			buf.append i, l
		end
EORUBY
	endfunction

	function! s:CalculateTotalMinutes()
		if getpos('.')[1] == 1 && len(getline(1)) == 0
			call s:CalculateTotalInvoiceMinutes()
		else
			call s:CalculateDailyMinutes()
			execute "normal \<Plug>OrgJumpToNextSkipChildrenNormal"
		endif
	endfunction
endif

command! -bar GoBufferSetup call <SID>GoBufferSetup()
function! s:GoBufferSetup()
	set laststatus=2
	setlocal statusline=%f\ %{go#statusline#Show()}%=%-15(%l,%c%)%P

	noremap! <buffer> <C-h>          <-
	noremap! <buffer> <C-l>          <Space>:=<Space>
	nmap     <buffer> <C-]>          <Plug>(go-def)
	nmap     <buffer> <C-w><C-]>     <Plug>(go-def-vertical)
	nmap     <buffer> [C             <Plug>(go-callers)
	nmap     <buffer> ]C             <Plug>(go-callees)
	nmap     <buffer> [d             <Plug>(go-info)
	nmap     <buffer> ]d             <Plug>(go-describe)
	nmap     <buffer> <LocalLeader>a <Plug>(go-alternate-edit)
	nmap     <buffer> <LocalLeader>A <Plug>(go-alternate-vertical)
	nmap     <buffer> <LocalLeader>b <Plug>(go-build)
	nmap     <buffer> <LocalLeader>c <Plug>(go-channelpeers)
	nmap     <buffer> <LocalLeader>C <Plug>(go-coverage)
	nmap     <buffer> <LocalLeader><M-c> <Plug>(go-coverage-clear)
	noremap  <buffer> <LocalLeader>d :<C-u>GoDoc<Space>
	noremap  <buffer> <LocalLeader>D :<C-u>GoDocBrowser<Space>
	noremap  <buffer> <LocalLeader>e :<C-u>GoErrCheck -abspath<CR>
	noremap  <buffer> <LocalLeader>E :<C-u>GoErrCheck -ignore=fmt:^$ -abspath -asserts -blank<CR>
	nmap     <buffer> <LocalLeader>f vaB:GoFreevars<CR>
	vnoremap <buffer> <LocalLeader>f :GoFreevars<CR>
	nmap     <buffer> <LocalLeader>g :<C-u>execute 'GoGuruScope ' . (exists('g:go_guru_scope') ? '""' : '...')<CR>
	nmap     <buffer> <LocalLeader>i <Plug>(go-install)
	nmap     <buffer> <LocalLeader>I <Plug>(go-implements)
	noremap  <buffer> <LocalLeader>l :<C-u>GoMetaLinter<CR>
	noremap  <buffer> <LocalLeader>L :<C-u>GoLint -min_confidence=0<CR>
	noremap  <buffer> <LocalLeader>o :<C-u>GoOptimizations<CR>
	nmap     <buffer> <LocalLeader>r <Plug>(go-referrers)
	nmap     <buffer> <LocalLeader>R <Plug>(go-rename)
	nmap     <buffer> <LocalLeader>s <Plug>(go-callstack)
	nmap     <buffer> <LocalLeader>S :<C-u>GoAssemble<CR>
	noremap  <buffer> <LocalLeader>t :<C-u>GoTest -tags test<CR>
	noremap  <buffer> <LocalLeader>T :<C-u>GoTestFunc -tags test<CR>
	noremap  <buffer> <LocalLeader><M-t> :<C-u>GoTest -tags test -race<CR>
	nmap     <buffer> <LocalLeader>v <Plug>(go-vet)
endfunction

function! s:CompareQuickfix(p, q)
	let p = bufname(a:p['bufnr'])
	let q = bufname(a:q['bufnr'])
	return p > q ? 1 : (p < q ? -1 : (a:p['lnum'] > a:q['lnum'] ? 1 : -1))
endfunction

command! -bar GoOptimizations call <SID>GoOptimizations()
function! s:GoOptimizations()
	setlocal makeprg=go\ build\ -gcflags=-m\\\ -d=ssa/check_bce,ssa/prove
	silent! make

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

	setlocal makeprg&
endfunction

command! -bar GoAssemble call <SID>GoAssemble()
function! s:GoAssemble()
	let cmd = stridx(expand('%'), '_test') > -1 ? 'test -run=✖' : 'build'
	Sscratch
	setfiletype plain
	normal! gg"_dG
	execute 'r!go ' . cmd . ' -gcflags=-S 2>&1 | ruby -e "puts \$stdin.read.gsub(/\\(\#{Regexp.escape Dir.pwd}\\//, \%q{(})"'
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

command! -nargs=? -complete=command -bar Qfdo call <SID>Listdo(getqflist(), <q-args>) "{{{1
command! -nargs=? -complete=command -bar Locdo call <SID>Listdo(getloclist(0), <q-args>) "{{{1
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
		try
			topleft lwindow | wincmd p
			cwindow | wincmd p
		catch /./
			lclose | cclose | pclose
		endtry
	else
		lclose | cclose | pclose
	endif
endfunction

command! -bar DeniteOpen call fugitive#detect('.') | execute 'Denite ' . (exists('b:git_dir') ? 'git' : 'file_rec')

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
		execute 'lcd ' . g:org_home | Denite git
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
		Σ + BigDecimal.new(n)
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
