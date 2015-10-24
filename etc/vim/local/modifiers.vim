""" Modifier Setup: Alt and Mod4

" http://vim.wikia.com/wiki/Fix_meta-keys_that_break_out_of_Insert_mode
" http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim

" Set value of keycode or map in all modes {{{1
command! -nargs=+ Setmap call <SID>Setmap(<f-args>)
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
    "  * Esc-O is the SS3 prefix (Single Shift Select of G3 Character Set)
    if char !=# '[' && char !=# 'O'
        execute 'Setmap <M-' . char . "> \<Esc>" . key
    endif

    " Super / Mod4
    "  * Assumes terminal sends \033\007 as the Mod4 prefix. This can be
    "    accomplished in rxvt-unicode using the keysym-list extension:
    "
    "    ~/.Xdefaults:
    "       URxvt.keysym.Mod4-0x20: list	\033\007	 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~	
    "
    "   Note that literal tab characters are used as delimiters as the
    "   resource argument contains a list of all printable ASCII characters.
    execute 'Setmap <4-' . char . "> \<Esc>\<C-g>" . key
endfor

unlet namedkeys n

""" Special Keys {{{1

" Backspace
execute "Setmap <C-BS>       \<C-h>"
execute "Setmap <M-BS>       \<Esc><BS>"

" Return
execute "Setmap <M-CR>       \<Esc>\<CR>"
execute "Setmap <4-CR>       \<Esc>\<C-g>\<CR>"

" Backslash
execute "Setmap <M-Bslash>   \<Esc>\\"

" Arrow keys
if exists('$TMUX')
    execute "Setmap <C-Up>       \<Esc>[A"
    execute "Setmap <C-Down>     \<Esc>[B"
    execute "Setmap <C-Right>    \<Esc>[C"
    execute "Setmap <C-Left>     \<Esc>[D"
else
    execute "Setmap <C-Up>       \<Esc>Oa"
    execute "Setmap <C-Down>     \<Esc>Ob"
    execute "Setmap <C-Right>    \<Esc>Oc"
    execute "Setmap <C-Left>     \<Esc>Od"
endif

execute "Setmap <S-Up>       \<Esc>[a"
execute "Setmap <S-Down>     \<Esc>[b"
execute "Setmap <S-Right>    \<Esc>[c"
execute "Setmap <S-Left>     \<Esc>[d"

execute "Setmap <M-Up>       \<Esc><Up>"
execute "Setmap <M-Down>     \<Esc><Down>"
execute "Setmap <M-Right>    \<Esc><Right>"
execute "Setmap <M-Left>     \<Esc><Left>"

execute "Setmap <4-Up>       \<Esc>\<C-g>\<C-g>a"
execute "Setmap <4-Down>     \<Esc>\<C-g>\<C-g>b"
execute "Setmap <4-Right>    \<Esc>\<C-g>\<C-g>c"
execute "Setmap <4-Left>     \<Esc>\<C-g>\<C-g>d"

execute "Setmap <4-S-Up>     \<Esc>\<C-g>\<C-g>A"
execute "Setmap <4-S-Down>   \<Esc>\<C-g>\<C-g>B"
execute "Setmap <4-S-Right>  \<Esc>\<C-g>\<C-g>C"
execute "Setmap <4-S-Left>   \<Esc>\<C-g>\<C-g>D"

""" Cleanup {{{1

delcommand  Setmap
delfunction s:Setmap
