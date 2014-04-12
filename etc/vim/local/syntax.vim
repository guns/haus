""" Syntax Initialization

syntax on
set synmaxcol=300 " Avoids editor lockup in files with extremely long lines.

if &t_Co == 256 || has('gui_running')
    let g:jellyx_show_whitespace = 1
    colorscheme jellyx
else
    set list " Fall back on invisibles for showing whitespace errors
    colorscheme peachpuff
endif
