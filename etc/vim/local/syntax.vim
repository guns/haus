""" Syntax Initialization

syntax on
set synmaxcol=160 " Speeds up syntax parsing considerably

if &t_Co == 256 || has('gui_running')
    let g:jellyx_show_whitespace = 1
    colorscheme jellyx
else
    set list " Fall back on invisibles for showing whitespace errors
    colorscheme peachpuff
endif
