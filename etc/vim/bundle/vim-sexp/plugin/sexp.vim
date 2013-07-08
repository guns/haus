
"              o8o
"              '"'
"  oooo    ooooooo ooo. .oo.  .oo.        .oooo.o  .ooooo. oooo    ooooo.ooooo.
"   `88.  .8' `888 `888P"Y88bP"Y88b      d88(  "8 d88' `88b `88b..8P'  888' `88b
"    `88..8'   888  888   888   888 8888 `"Y88b.  888ooo888   Y888'    888   888
"     `888'    888  888   888   888      o.  )88b 888    .o .o8"'88b   888   888
"      `8'    o888oo888o o888o o888o     8""888P' `Y8bod8P'o88'   888o 888bod8P'
"                                                                      888
"                                                                     o888o
"  Author:   guns <self@sungpae.com>
"  License:  MIT
"  Homepage: https://github.com/guns/vim-sexp

if exists('g:sexp_loaded')
    finish
endif
let g:sexp_loaded = 1

""" Global State {{{1

if !exists('g:sexp_filetypes')
    let g:sexp_filetypes = 'clojure,scheme,lisp'
endif

if !exists('g:sexp_enable_insert_mode_mappings')
    let g:sexp_enable_insert_mode_mappings = 1
endif

if !exists('g:sexp_insert_after_wrap')
    let g:sexp_insert_after_wrap = 1
endif

if !exists('g:sexp_mappings')
    let g:sexp_mappings = {}
endif

let s:sexp_mappings = {
    \ 'sexp_outer_list':                'af',
    \ 'sexp_inner_list':                'if',
    \ 'sexp_outer_top_list':            'aF',
    \ 'sexp_inner_top_list':            'iF',
    \ 'sexp_outer_string':              'as',
    \ 'sexp_inner_string':              'is',
    \ 'sexp_outer_element':             'ae',
    \ 'sexp_inner_element':             'ie',
    \ 'sexp_move_to_prev_bracket':      '(',
    \ 'sexp_move_to_next_bracket':      ')',
    \ 'sexp_move_to_prev_element_head': '<M-b>',
    \ 'sexp_move_to_next_element_head': '<M-w>',
    \ 'sexp_move_to_prev_element_tail': 'g<M-e>',
    \ 'sexp_move_to_next_element_tail': '<M-e>',
    \ 'sexp_move_to_prev_top_element':  '[[',
    \ 'sexp_move_to_next_top_element':  ']]',
    \ 'sexp_select_prev_element':       '[e',
    \ 'sexp_select_next_element':       ']e',
    \ 'sexp_round_head_wrap_list':      '<LocalLeader>i',
    \ 'sexp_round_tail_wrap_list':      '<LocalLeader>I',
    \ 'sexp_square_head_wrap_list':     '<LocalLeader>[',
    \ 'sexp_square_tail_wrap_list':     '<LocalLeader>]',
    \ 'sexp_curly_head_wrap_list':      '<LocalLeader>{',
    \ 'sexp_curly_tail_wrap_list':      '<LocalLeader>}',
    \ 'sexp_round_head_wrap_element':   '<LocalLeader>w',
    \ 'sexp_round_tail_wrap_element':   '<LocalLeader>W',
    \ 'sexp_square_head_wrap_element':  '<LocalLeader>e[',
    \ 'sexp_square_tail_wrap_element':  '<LocalLeader>e]',
    \ 'sexp_curly_head_wrap_element':   '<LocalLeader>e{',
    \ 'sexp_curly_tail_wrap_element':   '<LocalLeader>e}',
    \ 'sexp_splice_list':               '<LocalLeader>@',
    \ 'sexp_lift_list':                 '<LocalLeader>o',
    \ 'sexp_lift_element':              '<LocalLeader>O',
    \ 'sexp_swap_list_backward':        '<M-k>',
    \ 'sexp_swap_list_forward':         '<M-j>',
    \ 'sexp_swap_element_backward':     '<M-h>',
    \ 'sexp_swap_element_forward':      '<M-l>',
    \ 'sexp_emit_head_element':         '<M-S-j>',
    \ 'sexp_emit_tail_element':         '<M-S-k>',
    \ 'sexp_capture_prev_element':      '<M-S-h>',
    \ 'sexp_capture_next_element':      '<M-S-l>',
    \ 'sexp_insert_at_list_head':       '<LocalLeader>h',
    \ 'sexp_insert_at_list_tail':       '<LocalLeader>l',
    \ }

augroup sexp_filetypes
    autocmd!
    if !empty(g:sexp_filetypes)
        execute 'autocmd FileType ' . g:sexp_filetypes . ' call s:sexp_create_mappings()'
    endif
augroup END

silent! call repeat#set('') " Autoload repeat.vim

""" Functions {{{1

command! -nargs=+ -bang Defplug call <SID>defplug('<bang>', <f-args>)
command! -nargs=+ -bang DEFPLUG call <SID>defplug('<bang>*', <f-args>)

" Create a <Plug> mapping. The 'mode' parameter dictates the behavior:
"
"   * mode == '' : Map to calling rhs as expression
"   * mode == '!': Map to calling rhs as expression, setting up repeat
"   * mode == '*': Map to rhs as a key sequence
"
function! s:defplug(mode, mapmode, name, ...)
    let lhs = a:mapmode . ' <silent> <Plug>' . a:name
    let rhs = join(a:000)
    let should_repeat = a:mode ==# '!'

    if a:mode ==# '*'
        execute lhs . ' ' . rhs
    elseif empty(a:mode) || (should_repeat && !exists('*repeat#set'))
        " TODO: Only first visual motion should set '`
        execute lhs . ' '
                \ . ':<C-u>call setpos("' . "'`" . '", getpos(".")) \| '
                \ . 'call ' . rhs . '<CR>'
    elseif should_repeat && a:mapmode[0] ==# 'o'
        " Due to a bug in vim, we need to set curwin->w_curswant to the
        " current cursor position by entering and exiting character-wise
        " visual mode before completing the operator-pending command so that
        " the cursor returns to it's original position after an = command.
        execute lhs . ' '
                \ . ':<C-u>let b:sexp_count = v:count \| '
                \ . 'execute "normal! vv" \| '
                \ . 'call setpos("' . "'`" . '", getpos(".")) \| '
                \ . 'call ' . substitute(rhs, '\v<v:count>', 'b:sexp_count', 'g') . ' \| '
                \ . 'if v:operator ==? "c" \| '
                \ . '  call <SID>repeat_set(v:operator . "\<Plug>' . a:name . '\<lt>C-r>.\<lt>C-Bslash>\<lt>C-n>", b:sexp_count) \| '
                \ . 'else \| '
                \ . '  call <SID>repeat_set(v:operator . "\<Plug>' . a:name . '", b:sexp_count) \| '
                \ . 'endif<CR>'
    elseif should_repeat
        execute lhs . ' '
                \ . ':<C-u>let b:sexp_count = v:count \| '
                \ . 'call setpos("' . "'`" . '", getpos(".")) \| '
                \ . 'call ' . substitute(rhs, '\v<v:count>', 'b:sexp_count', 'g') . ' \| '
                \ . 'call <SID>repeat_set("\<Plug>' . a:name . '", b:sexp_count)<CR>'
    endif
endfunction

" Calls repeat#set() and registers a one-time CursorMoved handler to correctly
" set the value of g:repeat_tick.
"
" cf. https://github.com/tpope/vim-repeat/issues/8#issuecomment-13951082
function! s:repeat_set(buf, count)
    call repeat#set(a:buf, a:count)
    augroup sexp_repeat
        autocmd!
        autocmd CursorMoved <buffer> let g:repeat_tick = b:changedtick | autocmd! sexp_repeat
    augroup END
endfunction

" Bind <Plug> mappings in current buffer to values in g:sexp_mappings or
" s:sexp_mappings
function! s:sexp_create_mappings()
    for plug in ['sexp_outer_list',     'sexp_inner_list',
               \ 'sexp_outer_top_list', 'sexp_inner_top_list',
               \ 'sexp_outer_string',   'sexp_inner_string',
               \ 'sexp_outer_element',  'sexp_inner_element']
        let lhs = get(g:sexp_mappings, plug, s:sexp_mappings[plug])
        if !empty(lhs)
            execute 'xmap <silent><buffer> ' . lhs . ' <Plug>' . plug
            execute 'omap <silent><buffer> ' . lhs . ' <Plug>' . plug
        endif
    endfor

    for plug in ['sexp_move_to_prev_bracket',      'sexp_move_to_next_bracket',
               \ 'sexp_move_to_prev_element_head', 'sexp_move_to_next_element_head',
               \ 'sexp_move_to_prev_element_tail', 'sexp_move_to_next_element_tail',
               \ 'sexp_move_to_prev_top_element',  'sexp_move_to_next_top_element',
               \ 'sexp_select_prev_element',       'sexp_select_next_element']
        let lhs = get(g:sexp_mappings, plug, s:sexp_mappings[plug])
        if !empty(lhs)
            execute 'nmap <silent><buffer> ' . lhs . ' <Plug>' . plug
            execute 'xmap <silent><buffer> ' . lhs . ' <Plug>' . plug
            execute 'omap <silent><buffer> ' . lhs . ' <Plug>' . plug
        endif
    endfor

    for plug in ['sexp_round_head_wrap_list',     'sexp_round_tail_wrap_list',
               \ 'sexp_square_head_wrap_list',    'sexp_square_tail_wrap_list',
               \ 'sexp_curly_head_wrap_list',     'sexp_curly_tail_wrap_list',
               \ 'sexp_round_head_wrap_element',  'sexp_round_tail_wrap_element',
               \ 'sexp_square_head_wrap_element', 'sexp_square_tail_wrap_element',
               \ 'sexp_curly_head_wrap_element',  'sexp_curly_tail_wrap_element',
               \ 'sexp_splice_list',
               \ 'sexp_lift_list',                'sexp_lift_element',
               \ 'sexp_swap_list_backward',       'sexp_swap_list_forward',
               \ 'sexp_swap_element_backward',    'sexp_swap_element_forward',
               \ 'sexp_emit_head_element',        'sexp_emit_tail_element',
               \ 'sexp_capture_prev_element',     'sexp_capture_next_element',
               \ 'sexp_insert_at_list_head',      'sexp_insert_at_list_tail']
        let lhs = get(g:sexp_mappings, plug, s:sexp_mappings[plug])
        if !empty(lhs)
            execute 'nmap <silent><buffer> ' . lhs . ' <Plug>' . plug
            execute 'xmap <silent><buffer> ' . lhs . ' <Plug>' . plug
        endif
    endfor

    if g:sexp_enable_insert_mode_mappings
        imap <buffer> (    <Plug>sexp_insert_opening_round
        imap <buffer> [    <Plug>sexp_insert_opening_square
        imap <buffer> {    <Plug>sexp_insert_opening_curly
        imap <buffer> )    <Plug>sexp_insert_closing_round
        imap <buffer> ]    <Plug>sexp_insert_closing_square
        imap <buffer> }    <Plug>sexp_insert_closing_curly
        imap <buffer> "    <Plug>sexp_insert_double_quote
        imap <buffer> <BS> <Plug>sexp_insert_backspace
    endif
endfunction

""" Text Object Selections {{{1

" Current list (compound FORM)
Defplug  xnoremap sexp_outer_list sexp#docount(v:count, 'sexp#select_current_list', 'v', 0, 1)
Defplug! onoremap sexp_outer_list sexp#docount(v:count, 'sexp#select_current_list', 'o', 0, 1)
Defplug  xnoremap sexp_inner_list sexp#docount(v:count, 'sexp#select_current_list', 'v', 1, 1)
Defplug! onoremap sexp_inner_list sexp#docount(v:count, 'sexp#select_current_list', 'o', 1, 1)

" Current top-level list (compound FORM)
Defplug  xnoremap sexp_outer_top_list sexp#select_current_top_list('v', 0)
Defplug! onoremap sexp_outer_top_list sexp#select_current_top_list('o', 0)
Defplug  xnoremap sexp_inner_top_list sexp#select_current_top_list('v', 1)
Defplug! onoremap sexp_inner_top_list sexp#select_current_top_list('o', 1)

" Current string
Defplug  xnoremap sexp_outer_string sexp#select_current_string('v', 0)
Defplug! onoremap sexp_outer_string sexp#select_current_string('o', 0)
Defplug  xnoremap sexp_inner_string sexp#select_current_string('v', 1)
Defplug! onoremap sexp_inner_string sexp#select_current_string('o', 1)

" Current element
Defplug  xnoremap sexp_outer_element sexp#select_current_element('v', 0)
Defplug! onoremap sexp_outer_element sexp#select_current_element('o', 0)
Defplug  xnoremap sexp_inner_element sexp#select_current_element('v', 1)
Defplug! onoremap sexp_inner_element sexp#select_current_element('o', 1)

""" Directional motions {{{1

" Nearest bracket
Defplug  nnoremap sexp_move_to_prev_bracket sexp#docount(v:count, 'sexp#move_to_nearest_bracket', 'n', 0)
DEFPLUG  xnoremap sexp_move_to_prev_bracket <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_nearest_bracket', 'v', 0)<CR>
Defplug! onoremap sexp_move_to_prev_bracket sexp#docount(v:count, 'sexp#move_to_nearest_bracket', 'o', 0)
Defplug  nnoremap sexp_move_to_next_bracket sexp#docount(v:count, 'sexp#move_to_nearest_bracket', 'n', 1)
DEFPLUG  xnoremap sexp_move_to_next_bracket <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_nearest_bracket', 'v', 1)<CR>
Defplug! onoremap sexp_move_to_next_bracket sexp#docount(v:count, 'sexp#move_to_nearest_bracket', 'o', 1)

" Adjacent element head
"
" Visual mappings must break out of visual mode in order to detect which end
" the user is using to adjust the selection.
Defplug  nnoremap sexp_move_to_prev_element_head sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'n', 0, 0, 0)
DEFPLUG  xnoremap sexp_move_to_prev_element_head <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_adjacent_element', 'v', 0, 0, 0)<CR>
Defplug! onoremap sexp_move_to_prev_element_head sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'o', 0, 0, 0)
Defplug  nnoremap sexp_move_to_next_element_head sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'n', 1, 0, 0)
DEFPLUG  xnoremap sexp_move_to_next_element_head <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_adjacent_element', 'v', 1, 0, 0)<CR>
Defplug! onoremap sexp_move_to_next_element_head sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'o', 1, 0, 0)

" Adjacent element tail
"
" Inclusive operator pending motions require a visual mode selection to
" include the last character of a line.
"
" NOTE: abs(0) is a NOP in order to complete the argument to 'call' in defplug
Defplug  nnoremap sexp_move_to_prev_element_tail sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'n', 0, 1, 0)
DEFPLUG  xnoremap sexp_move_to_prev_element_tail <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_adjacent_element', 'v', 0, 1, 0)<CR>
Defplug! onoremap sexp_move_to_prev_element_tail abs(0) \| execute "normal! v\<lt>Esc>" \| call sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'v', 0, 1, 0)
Defplug  nnoremap sexp_move_to_next_element_tail sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'n', 1, 1, 0)
DEFPLUG  xnoremap sexp_move_to_next_element_tail <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_adjacent_element', 'v', 1, 1, 0)<CR>
Defplug! onoremap sexp_move_to_next_element_tail abs(0) \| execute "normal! v\<lt>Esc>" \| call sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'v', 1, 1, 0)

" Adjacent top element
Defplug  nnoremap sexp_move_to_prev_top_element sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'n', 0, 0, 1)
DEFPLUG  xnoremap sexp_move_to_prev_top_element <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_adjacent_element', 'v', 0, 0, 1)<CR>
Defplug! onoremap sexp_move_to_prev_top_element sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'o', 0, 0, 1)
Defplug  nnoremap sexp_move_to_next_top_element sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'n', 1, 0, 1)
DEFPLUG  xnoremap sexp_move_to_next_top_element <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#move_to_adjacent_element', 'v', 1, 0, 1)<CR>
Defplug! onoremap sexp_move_to_next_top_element sexp#docount(v:count, 'sexp#move_to_adjacent_element', 'o', 1, 0, 1)

" Adjacent element selection
"
" Unlike the other directional motions, calling this from normal mode places
" us in visual mode, with the adjacent element as our selection.
Defplug  nnoremap sexp_select_prev_element sexp#docount(v:count, 'sexp#select_adjacent_element', 'n', 0)
Defplug  xnoremap sexp_select_prev_element sexp#docount(v:count, 'sexp#select_adjacent_element', 'v', 0)
Defplug! onoremap sexp_select_prev_element sexp#docount(v:count, 'sexp#select_adjacent_element', 'o', 0)
Defplug  nnoremap sexp_select_next_element sexp#docount(v:count, 'sexp#select_adjacent_element', 'n', 1)
Defplug  xnoremap sexp_select_next_element sexp#docount(v:count, 'sexp#select_adjacent_element', 'v', 1)
Defplug! onoremap sexp_select_next_element sexp#docount(v:count, 'sexp#select_adjacent_element', 'o', 1)

""" Commands {{{1

" Wrap list
Defplug! nnoremap sexp_round_head_wrap_list  sexp#wrap('f', '(', ')', 0, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_round_head_wrap_list  sexp#wrap('v', '(', ')', 0, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_round_tail_wrap_list  sexp#wrap('f', '(', ')', 1, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_round_tail_wrap_list  sexp#wrap('v', '(', ')', 1, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_square_head_wrap_list sexp#wrap('f', '[', ']', 0, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_square_head_wrap_list sexp#wrap('v', '[', ']', 0, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_square_tail_wrap_list sexp#wrap('f', '[', ']', 1, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_square_tail_wrap_list sexp#wrap('v', '[', ']', 1, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_curly_head_wrap_list  sexp#wrap('f', '{', '}', 0, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_curly_head_wrap_list  sexp#wrap('v', '{', '}', 0, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_curly_tail_wrap_list  sexp#wrap('f', '{', '}', 1, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_curly_tail_wrap_list  sexp#wrap('v', '{', '}', 1, g:sexp_insert_after_wrap)

" Wrap element
Defplug! nnoremap sexp_round_head_wrap_element  sexp#wrap('e', '(', ')', 0, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_round_head_wrap_element  sexp#wrap('v', '(', ')', 0, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_round_tail_wrap_element  sexp#wrap('e', '(', ')', 1, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_round_tail_wrap_element  sexp#wrap('v', '(', ')', 1, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_square_head_wrap_element sexp#wrap('e', '[', ']', 0, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_square_head_wrap_element sexp#wrap('v', '[', ']', 0, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_square_tail_wrap_element sexp#wrap('e', '[', ']', 1, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_square_tail_wrap_element sexp#wrap('v', '[', ']', 1, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_curly_head_wrap_element  sexp#wrap('e', '{', '}', 0, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_curly_head_wrap_element  sexp#wrap('v', '{', '}', 0, g:sexp_insert_after_wrap)
Defplug! nnoremap sexp_curly_tail_wrap_element  sexp#wrap('e', '{', '}', 1, g:sexp_insert_after_wrap)
Defplug  xnoremap sexp_curly_tail_wrap_element  sexp#wrap('v', '{', '}', 1, g:sexp_insert_after_wrap)

" Lift list
Defplug! nnoremap sexp_lift_list    sexp#docount(v:count, 'sexp#lift', 'n', 'sexp#select_current_list', 'n', 0, 0)
Defplug  xnoremap sexp_lift_list    sexp#docount(v:count, 'sexp#lift', 'v', '')
Defplug! nnoremap sexp_lift_element sexp#docount(v:count, 'sexp#lift', 'n', 'sexp#select_current_element', 'n', 1)
Defplug  xnoremap sexp_lift_element sexp#docount(v:count, 'sexp#lift', 'v', '')

" Splice list
Defplug! nnoremap sexp_splice_list sexp#docount(v:count, 'sexp#splice_list')
Defplug  xnoremap sexp_splice_list sexp#docount(v:count, 'sexp#splice_list')

" Swap list
Defplug! nnoremap sexp_swap_list_backward sexp#docount(v:count, 'sexp#swap_element', 'n', 0, 1)
DEFPLUG  xnoremap sexp_swap_list_backward <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#swap_element', 'v', 0, 1)<CR>
Defplug! nnoremap sexp_swap_list_forward  sexp#docount(v:count, 'sexp#swap_element', 'n', 1, 1)
DEFPLUG  xnoremap sexp_swap_list_forward  <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#swap_element', 'v', 1, 1)<CR>

" Swap element
Defplug! nnoremap sexp_swap_element_backward sexp#docount(v:count, 'sexp#swap_element', 'n', 0, 0)
DEFPLUG  xnoremap sexp_swap_element_backward <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#swap_element', 'v', 0, 0)<CR>
Defplug! nnoremap sexp_swap_element_forward  sexp#docount(v:count, 'sexp#swap_element', 'n', 1, 0)
DEFPLUG  xnoremap sexp_swap_element_forward  <Esc>:<C-u>call sexp#docount(v:prevcount, 'sexp#swap_element', 'v', 1, 0)<CR>

" Emit/capture element
Defplug! nnoremap sexp_emit_head_element    sexp#docount(v:count, 'sexp#stackop', 'n', 0, 0)
Defplug  xnoremap sexp_emit_head_element    sexp#docount(v:count, 'sexp#stackop', 'v', 0, 0)
Defplug! nnoremap sexp_emit_tail_element    sexp#docount(v:count, 'sexp#stackop', 'n', 1, 0)
Defplug  xnoremap sexp_emit_tail_element    sexp#docount(v:count, 'sexp#stackop', 'v', 1, 0)
Defplug! nnoremap sexp_capture_prev_element sexp#docount(v:count, 'sexp#stackop', 'n', 0, 1)
Defplug  xnoremap sexp_capture_prev_element sexp#docount(v:count, 'sexp#stackop', 'v', 0, 1)
Defplug! nnoremap sexp_capture_next_element sexp#docount(v:count, 'sexp#stackop', 'n', 1, 1)
Defplug  xnoremap sexp_capture_next_element sexp#docount(v:count, 'sexp#stackop', 'v', 1, 1)

" Insert at list terminal
Defplug! nnoremap sexp_insert_at_list_head sexp#insert_at_list_terminal(0)
Defplug  xnoremap sexp_insert_at_list_head sexp#insert_at_list_terminal(0)
Defplug! nnoremap sexp_insert_at_list_tail sexp#insert_at_list_terminal(1)
Defplug  xnoremap sexp_insert_at_list_tail sexp#insert_at_list_terminal(1)

""" Insert mode mappings {{{1

" Insert opening delimiter
inoremap <silent><expr> <Plug>sexp_insert_opening_round  sexp#opening_insertion('(')
inoremap <silent><expr> <Plug>sexp_insert_opening_square sexp#opening_insertion('[')
inoremap <silent><expr> <Plug>sexp_insert_opening_curly  sexp#opening_insertion('{')

" Insert closing delimiter
inoremap <silent><expr> <Plug>sexp_insert_closing_round  sexp#closing_insertion(')')
inoremap <silent><expr> <Plug>sexp_insert_closing_square sexp#closing_insertion(']')
inoremap <silent><expr> <Plug>sexp_insert_closing_curly  sexp#closing_insertion('}')

" Insert double quote
inoremap <silent><expr> <Plug>sexp_insert_double_quote sexp#quote_insertion('"')

" Delete paired delimiters
inoremap <silent><expr> <Plug>sexp_insert_backspace sexp#backspace_insertion()

""" Cleanup {{{1

delcommand Defplug
delcommand DEFPLUG
delfunction s:defplug
