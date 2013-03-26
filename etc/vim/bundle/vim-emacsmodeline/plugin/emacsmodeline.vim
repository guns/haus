" -*- mode: vim; tab-width: 4; indent-tabs-mode: nil; fill-column: 99 -*-
"
" emacsmodeline.vim
" Brief: Parse emacs mode line and setlocal in vim
" Version: 1.1
" Date: Feb 20, 2013
" Maintainer: Chris Pickel <sfiera@gmail.com>
"
" Installation: put this file under your ~/.vim/plugin/
"
" Usage:
"
" This script is used to parse emacs mode lines, for example:
" -*- tab-width: 4 -*-
"
" Which is the same meaning as:
" vim:shiftwidth=4:softtabstob=4:tabstop=4:
"
" Revisions:
"
" 0.1, May 18, 2007:
"  * Initial version with tab-width support by Yuxuan 'fishy' Wang <fishywang@gmail.com>.
" 1.0, Dec 23, 2010:
"  * Support for mode, fill-column, buffer-read-only, and indent-tabs-mode.
"  * Maintainership taken up by Chris Pickel <sfiera@gmail.com>.
" 1.1, Feb 20, 2013
"  * Prevent an exploit.  Not seen in the wild, but likely to be used by vengeful emacs users.
"

" No attempt is made to support vim versions before 7.0.
if version < 700
    finish
endif

if (!exists("g:emacs_modelines"))
    let g:emacs_modelines=5
endif

if (!exists('g:emacsModeDict'))
    let g:emacsModeDict = {}
endif

if (!has_key(g:emacsModeDict, 'c++'))
    let g:emacsModeDict['c++'] = 'cpp'
endif

if (!has_key(g:emacsModeDict, 'shell-script'))
    let g:emacsModeDict['shell-script'] = 'sh'
endif

function! <SID>FindParameterValue(modeline, emacs_name, value)
    let pattern = '\c' . '\(^\|.*;\)\s*' . a:emacs_name . ':\s*\(' . a:value . '\)\s*\($\|;.*\)'
    if a:modeline =~ pattern
        return substitute(a:modeline, pattern, '\2', '')
    endif
    return ''
endfunc

function! <SID>SetVimModeOption(modeline)
    let value = <SID>FindParameterValue(a:modeline, 'mode', '[A-Za-z_+-]\+')
    if strlen(value)
        let value = tolower(value)
        if (has_key(g:emacsModeDict, value))
            let value = g:emacsModeDict[value]
        endif
        exec 'setlocal filetype=' . value
    endif
endfunc

function! <SID>SetVimNumberOption(modeline, emacs_name, vim_name)
    let value = <SID>FindParameterValue(a:modeline, a:emacs_name, '\d\+')
    if strlen(value)
        exec 'setlocal ' . a:vim_name . '=' . value
    endif
endfunc

function! <SID>SetVimToggleOption(modeline, emacs_name, vim_name, nil_value)
    let value = <SID>FindParameterValue(a:modeline, a:emacs_name, '\S\+')
    if strlen(value)
        if (value == 'nil') == a:nil_value
            exec 'setlocal ' . a:vim_name
        else
            exec 'setlocal no' . a:vim_name
        end
    endif
endfunc

function! ParseEmacsModeLine()
    " Prepare to scan the first and last g:emacs_modelines lines.
    let max = line("$")
    if max > (g:emacs_modelines * 2)
        let lines = range(1, g:emacs_modelines) + range(max - g:emacs_modelines + 1, max)
    else
        let lines = range(1, max)
    endif

    let pattern = '.*-\*-\(.*\)-\*-.*'
    for n in lines
        let line = getline(n)
        if line =~ pattern
            let modeline = substitute(line, pattern, '\1', '')

            call <SID>SetVimModeOption(modeline)

            call <SID>SetVimNumberOption(modeline, 'fill-column',        'textwidth')
            call <SID>SetVimNumberOption(modeline, 'tab-width',          'shiftwidth')
            call <SID>SetVimNumberOption(modeline, 'tab-width',          'softtabstop')
            call <SID>SetVimNumberOption(modeline, 'tab-width',          'tabstop')

            call <SID>SetVimToggleOption(modeline, 'buffer-read-only',   'readonly',     0)
            call <SID>SetVimToggleOption(modeline, 'indent-tabs-mode',   'expandtab',    1)

            let value = substitute(modeline, '^ *\([^ ]*\) *$', '\L\1', '')
            if (has_key(g:emacsModeDict, value))
                exec 'setlocal filetype=' .  g:emacsModeDict[value]
            endif

            " Other emacs options seen in the wild include:
            "  * c-basic-offset: something like tab-width.
            "  * c-file-style: no vim equivalent (?).
            "  * coding: text encoding.  Non-UTF-8 files are evil.
            "  * compile-command: probably equivalent to &makeprg.  However, vim will refuse to
            "    set it from a modeline, as a security risk, and we follow that decision here.
            "  * mmm-classes: appears to be for other languages inline in HTML, e.g. PHP.
            "  * package: equal to mode, in the one place I've seen it.
            "  * syntax: equal to mode, in the one place I've seen it.
        endif
    endfor
endfunc

autocmd BufReadPost * :call ParseEmacsModeLine()
