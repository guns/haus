""" Modifier Setup: Alt and Mod4

" http://vim.wikia.com/wiki/Fix_meta-keys_that_break_out_of_Insert_mode
" http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim

" Set value of keycode or map in all modes {{{1
function! s:Setmap(map, seq)
	try
		" Some named values can be `set'
		execute 'set ' . a:map . '=' . a:seq
	catch
		" The rest can simply be mapped
		execute 'map  <special> ' . a:seq . ' ' . a:map
		execute 'map! <special> ' . a:seq . ' ' . a:map
	endtry
endfunction

let namedkeys = {
	\ ' ': 'Space',
	\ '\': 'Bslash',
	\ '|': 'Bar',
	\ '<': 'lt'
	\ }

" Map {Alt,Mod4} + ASCII printable chars {{{1
for n in range(0x20, 0x7e)
	let char = nr2char(n)
	let key  = char

	if has_key(namedkeys, char)
		let char = namedkeys[char]
		let key  = '<' . char . '>'
	endif

	" Escaped Meta (i.e. not 8-bit mode)
	"  * Esc-[ is the CSI prefix (Control Sequence Introducer)
	"  * Esc-] introduces another control mode
	if char !=# '[' && char !=# ']'
		call s:Setmap('<M-' . char . '>', "\<Esc>" . key)
	endif

	" Super / Mod4
	"  * Assumes terminal sends \033\007 as the Mod4 prefix. This can be
	"    accomplished in rxvt-unicode via the keysym feature:
	"
	"    ~/.Xdefaults:
	"       URxvt.keysym.Mod4-0x20:      \033\007\040
	"       URxvt.keysym.Mod4-0x21:      \033\007\041
	"       …
	"       URxvt.keysym.Mod4-0x7e:      \033\007\176
	call s:Setmap('<4-' . char . '>', "\<Esc>\<C-g>" . key)
endfor

unlet namedkeys n char key

""" Special Keys {{{1

" Backspace
call s:Setmap("<C-BS>", "\<C-h>")
call s:Setmap("<M-BS>", "\<Esc><BS>")

" Return
call s:Setmap("<M-CR>", "\<Esc>\<CR>")
call s:Setmap("<4-CR>", "\<Esc>\<C-g>\<CR>")

" Backslash
call s:Setmap("<M-Bslash>", "\<Esc>\\")

" Arrow keys
if exists('$TMUX')
	call s:Setmap("<C-Up>",    "\<Esc>[A")
	call s:Setmap("<C-Down>",  "\<Esc>[B")
	call s:Setmap("<C-Right>", "\<Esc>[C")
	call s:Setmap("<C-Left>",  "\<Esc>[D")
else
	call s:Setmap("<C-Up>",    "\<Esc>Oa")
	call s:Setmap("<C-Down>",  "\<Esc>Ob")
	call s:Setmap("<C-Right>", "\<Esc>Oc")
	call s:Setmap("<C-Left>",  "\<Esc>Od")
endif

call s:Setmap("<S-Up>",    "\<Esc>[a")
call s:Setmap("<S-Down>",  "\<Esc>[b")
call s:Setmap("<S-Right>", "\<Esc>[c")
call s:Setmap("<S-Left>",  "\<Esc>[d")

call s:Setmap("<M-Up>",    "\<Esc><Up>")
call s:Setmap("<M-Down>",  "\<Esc><Down>")
call s:Setmap("<M-Right>", "\<Esc><Right>")
call s:Setmap("<M-Left>",  "\<Esc><Left>")

call s:Setmap("<4-Up>",    "\<Esc>\<C-g>\<C-g>a")
call s:Setmap("<4-Down>",  "\<Esc>\<C-g>\<C-g>b")
call s:Setmap("<4-Right>", "\<Esc>\<C-g>\<C-g>c")
call s:Setmap("<4-Left>",  "\<Esc>\<C-g>\<C-g>d")

call s:Setmap("<4-S-Up>",    "\<Esc>\<C-g>\<C-g>A")
call s:Setmap("<4-S-Down>",  "\<Esc>\<C-g>\<C-g>B")
call s:Setmap("<4-S-Right>", "\<Esc>\<C-g>\<C-g>C")
call s:Setmap("<4-S-Left>",  "\<Esc>\<C-g>\<C-g>D")

delfunction s:Setmap
