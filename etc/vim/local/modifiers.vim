""" Modifier Normalization

" NOTE: This file contains non-printing characters!
"       It is advisable to edit or view this file in Vim

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

" Normalize Modifier + ASCII printable chars {{{1
for n in range(0x20, 0x7e)
    let char = nr2char(n)
    let key  = char

    if has_key(g:__NAMED_KEYCODES__, char)
        let char = g:__NAMED_KEYCODES__[char]
        let key  = '<' . char . '>'
    endif

    " Escaped Meta (i.e. not 8-bit mode)
    "  * Esc-[ is the CSI prefix (Control Sequence Introducer)
    "  * Esc-O is the SS3 prefix (Single Shift Select of G3 Character Set)
    if char !=# '[' && char !=# 'O'
        execute 'Setmap <M-' . char . '> ' . key
    endif

    " Super / Mod4
    "  * Assumes terminal sends <ESC><BEL> as Mod4 prefix; this can be
    "    accomplished in rxvt-unicode using the keysym-list extension:
    "
    "    ~/.Xdefaults:
    "       URxvt.keysym.Mod4-0x20: list\033\007 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~
    "
    "   Note that literal <US> (0x1f) characters are used as delimiters as the
    "   resource argument contains a list of all printable ASCII characters.
    execute 'Setmap <4-' . char . '> <Esc>' . key
endfor


""" Special Keys {{{1

" Backspace
Setmap <C-BS>       <C-h>
Setmap <M-BS>       <Esc><BS>

" Return
Setmap <M-CR>       
Setmap <4-CR>       <Esc><CR>

" Backslash
Setmap <M-Bslash>   \\

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

Setmap <M-Up>       <Esc><Up>
Setmap <M-Down>     <Esc><Down>
Setmap <M-Right>    <Esc><Right>
Setmap <M-Left>     <Esc><Left>

Setmap <4-Up>       <Esc>a
Setmap <4-Down>     <Esc>b
Setmap <4-Right>    <Esc>c
Setmap <4-Left>     <Esc>d

Setmap <4-S-Up>     <Esc>A
Setmap <4-S-Down>   <Esc>B
Setmap <4-S-Right>  <Esc>C
Setmap <4-S-Left>   <Esc>D


""" Cleanup {{{1

delcommand  Setmap
delfunction s:Setmap
