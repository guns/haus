""" Terminal Settings
" http://vim-fr.org/index.php/Julm

set mouse=a         " Enable full mouse support
set ttymouse=xterm2 " More accurate mouse tracking
set ttyfast         " More redrawing characters sent to terminal

" From ECMA-48:
"
"   OSC - OPERATING SYSTEM COMMAND:
"     Representation: 09/13 or ESC 05/13 (this is \033] here)
"     OSC is used as the opening delimiter of a control string for
"     operating system use.  The command string following may consist
"     of a sequence of bit combinations in the range 00/08 to 00/13 and
"     02/00 to 07/14.  The control string is closed by the terminating
"     delimiter STRING TERMINATOR (ST).  The interpretation of the
"     command string depends on the relevant operating system.
"
" From man screen:
"
"   Virtual Terminal -> Control Sequences:
"     ESC P  (A)  Device Control String
"                 Outputs a string directly to the host
"                 terminal without interpretation.
"     ESC \  (A)  String Terminator
"
" From tmux OpenBSD patchset 866:
"
"   Support passing through escape sequences to the underlying terminal
"   by using DCS with a "tmux;" prefix. Escape characters in the
"   sequences must be doubled. For example:
"
"   $ printf '\033Ptmux;\033\033]12;red\007\033\\'
"
"   Will pass \033]12;red\007 to the terminal (and change the cursor
"   colour in xterm). From Kevin Goodsell.
"
" From tmux OpenBSD patchsets 915 and 916:
"
"   Support xterm(1) cursor colour change sequences through terminfo(5) Cc
"   (set) and Cr (reset) extensions. Originally by Sean Estabrooks, tweaked
"   by me and Ailin Nemui.
"
"   Support DECSCUSR sequence to set the cursor style with two new
"   terminfo(5) extensions, Cs and Csr. Written by Ailin Nemui.
"
" From :help t_SI:
"
"   Added by Vim (there are no standard codes for these):
"     t_SI start insert mode (bar cursor shape)
"     t_EI end insert mode (block cursor shape)

if &t_Co == 256
    let s:icolor = 'rgb:00/CC/FF'
    let s:ncolor = 'rgb:FF/F5/9B'
    let s:ishape = '4 '
    let s:nshape = '2 '

    if &term =~ '\v^screen' && !exists('$TMUX')
        let &t_SI = "\033P\033]12;" . s:icolor . "\007\033\\\033P\033[" . s:ishape . "q\033\\"
        let &t_EI = "\033P\033]12;" . s:ncolor . "\007\033\\\033P\033[" . s:nshape . "q\033\\"
    elseif exists('$TMUX') || &term =~ '\v^tmux' || &term =~ '\v^u?rxvt' || &term =~ '\v^xterm'
        let &t_SI = "\033]12;" . s:icolor . "\007\033[" . s:ishape . "q"
        let &t_EI = "\033]12;" . s:ncolor . "\007\033[" . s:nshape . "q"
    endif
endif
