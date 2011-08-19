""" Syntax Initialization

if !has('syntax')
    finish
endif

syntax on
set synmaxcol=160 " speeds up syntax parsing considerably

if &t_Co == 256 || has('gui_running')
    " set cursorline
    let g:jellyx_show_whitespace = 1
    colorscheme jellyx
else
    set list " fall back on invisibles for showing whitespace errors
    colorscheme peachpuff
endif
