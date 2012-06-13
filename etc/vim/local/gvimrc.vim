""" GUI Settings

" c - use console dialogs and prompts
set guioptions=c

" Disable menus
let g:did_install_default_menus = 1
let g:did_install_syntax_menu = 1
aunmenu *

if has('gui_macvim')
    set fuoptions=maxvert,maxhorz
    set macmeta

    let g:macvim_skip_cmd_opt_movement = 1

    " Alias MacVim Command key to Super / Mod4
    let spkeys =  [ 'Up', 'Down', 'Left', 'Right',
                  \ 'S-Up', 'S-Down', 'S-Left', 'S-Right',
                  \ 'CR', 'BS' ]
    for n in range(0x20, 0x7e) + spkeys
        let char = type(n) == type(0) ? nr2char(n) : n

        if type(n) == type(0)
            let char = nr2char(n)
            if has_key(g:__NAMED_KEYCODES__, char)
                let char = g:__NAMED_KEYCODES__[char]
            endif
        else
            let char = n
        endif

        execute 'map  <special> <D-'.char.'> <4-'.char.'>'
        execute 'map! <special> <D-'.char.'> <4-'.char.'>'
    endfor
endif
