" Shebang: Automatically set shebang based on the filetype
" Author:  Johannes Hoff
" Date:    Jun 6, 2012

function! SetExecutableBit()
	" This function is taken from
	" http://vim.wikia.com/wiki/Setting_file_attributes_without_reloading_a_buffer
	" Thanks Max Ischenko!
	let fname = expand("%:p")
	checktime
	execute "au FileChangedShell " . fname . " :echo"
	silent !chmod a+x %
	checktime
	execute "au! FileChangedShell " . fname
endfunction

function! SetShebang()
python << endpython
import vim
shebang = {
	'python':     '#!/usr/bin/env python',
	'sh':         '#!/bin/sh',
	'bash':       '#!/usr/bin/env bash',
	'javascript': '#!/usr/bin/env node',
	'lua':        '#!/usr/bin/env lua',
	'ruby':       '#!/usr/bin/env ruby',
	'perl':       '#!/usr/bin/env perl',
	'php':        '#!/usr/bin/env php',
	'clojure':    '#!/usr/bin/env lein-exec',
}
if not vim.current.buffer[0].startswith('#!'):
	filetype = vim.eval('&filetype')
	if filetype in shebang:
		vim.current.buffer[0:0] = [ shebang[filetype] ]
endpython
endfunction

function! SetExecutable()
	call SetExecutableBit()
	call SetShebang()
endfunction
