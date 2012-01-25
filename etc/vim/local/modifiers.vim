""" Modifier Normalization

" NOTE: This file contains non-printing characters;
"       it is best viewed from within Vim

" http://vim.wikia.com/wiki/Fix_meta-keys_that_break_out_of_Insert_mode
" http://vim.wikia.com/wiki/Mapping_fast_keycodes_in_terminal_Vim

" Set value of keycode or map in all modes {{{1
command! -nargs=+ Setmap call <SID>Setmap(<f-args>)
function! <SID>Setmap(map, seq)
    " Some named values can be `set'
    try
        execute 'set ' . a:map . '=' . a:seq
    " but the rest can simply be mapped
    catch
        execute 'map  <special> ' . a:seq . ' ' . a:map
        execute 'map! <special> ' . a:seq . ' ' . a:map
    endtry
endfunction

" Named keycodes {{{1
let g:named_keycode = {
    \ ' ': 'Space',
    \ '\': 'Bslash',
    \ '|': 'Bar',
    \ '<': 'lt'
\ }

" Normalize mod + ASCII printable chars {{{1
for n in range(0x20, 0x7e)
    let char = nr2char(n)
    let key  = char

    if has_key(g:named_keycode, char)
        let char = g:named_keycode[char]
        let key  = '<' . char . '>'
    endif

    " Option / Alt as Meta
    "  * M-[ is ^[[, which is terminal escape
    "  * M-" doesn't work
    "  * M-O is escape for arrow keys
    if char !=# '[' && char !=# '"' && char !=# 'O'
        execute 'Setmap <M-' . char . '> ' . key
    endif

    " Super / Mod4
    "  * Assumes terminal sends <Esc><Space> as Mod4 prefix
    execute 'Setmap <4-' . char . '> \ ' . key
endfor


""" Special Keys {{{1

" Backspace
Setmap <C-BS>       
Setmap <M-BS>       

" Arrow keys
if exists('$TMUX')
    Setmap <C-Up>       [A
    Setmap <C-Down>     [B
    Setmap <C-Right>    [C
    Setmap <C-Left>     [D
else
    Setmap <C-Up>       Oa
    Setmap <C-Down>     Ob
    Setmap <C-Right>    Oc
    Setmap <C-Left>     Od
endif

Setmap <S-Up>       [a
Setmap <S-Down>     [b
Setmap <S-Right>    [c
Setmap <S-Left>     [d

Setmap <M-Up>       <Up>
Setmap <M-Down>     <Down>
Setmap <M-Right>    <Right>
Setmap <M-Left>     <Left>

Setmap <4-Up>       \ a
Setmap <4-Down>     \ b
Setmap <4-Right>    \ c
Setmap <4-Left>     \ d

Setmap <4-S-Up>     \ A
Setmap <4-S-Down>   \ B
Setmap <4-S-Right>  \ C
Setmap <4-S-Left>   \ D

" Return
Setmap <M-CR>       
Setmap <4-CR>       \ 

" Backspace / Delete
Setmap <4-BS>       \ 

" Backslash
Setmap <M-Bslash>   \\


""" Cleanup {{{1

delcommand  Setmap
delfunction <SID>Setmap
