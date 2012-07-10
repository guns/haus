" Sparkup
" Installation:
"    Copy the contents of vim/ftplugin/ to your ~/.vim/ftplugin directory.
"
"        $ cp -R vim/ftplugin ~/.vim/ftplugin/
"
" Configuration:
"   g:sparkup (Default: 'sparkup') -
"     Location of the sparkup executable. You shouldn't need to change this
"     setting if you used the install option above.
"
"   g:sparkupArgs (Default: '--no-last-newline') -
"     Additional args passed to sparkup.
"
"   g:sparkupExecuteMapping (Default: '<c-e>') -
"     Mapping used to execute sparkup.
"
"   g:sparkupNextMapping (Default: '<c-n>') -
"     Mapping used to jump to the next empty tag/attribute.

if exists('*s:Sparkup')
    finish
endif

command! -bar SparkupBufferSetup call <SID>SparkupBufferSetup()
function! <SID>SparkupBufferSetup()
    if exists('b:SparkupBufferSetup')
        unlet b:SparkupBufferSetup
        silent nunmap <buffer> <Leader>-
        silent nunmap <buffer> --
    else
        let b:SparkupBufferSetup = 1
        silent nmap <buffer> <Leader>- :call <SID>Sparkup()<cr>
        silent nmap <buffer> --        :call <SID>SparkupNext()<cr>
    endif
endfunction

function! s:Sparkup()
    if !exists('s:sparkup')
        let s:sparkup = exists('g:sparkup') ? g:sparkup : 'sparkup'
        let s:sparkupArgs = exists('g:sparkupArgs') ? g:sparkupArgs : '--no-last-newline'
        " check the user's path first. if not found then search relative to
        " sparkup.vim in the runtimepath.
        if !executable(s:sparkup)
            let paths = substitute(escape(&runtimepath, ' '), '\(,\|$\)', '/**\1', 'g')
            let s:sparkup = findfile('sparkup.py', paths)

            if !filereadable(s:sparkup)
                echohl WarningMsg
                echom 'Warning: could not find sparkup on your path or in your vim runtime path.'
                echohl None
                finish
            endif
        endif
        let s:sparkup = '"' . s:sparkup . '"'
        let s:sparkup .= printf(' %s --indent-spaces=%s', s:sparkupArgs, &shiftwidth)
        if has('win32') || has('win64')
            let s:sparkup = 'python ' . s:sparkup
        endif
    endif
    exec '.!' . s:sparkup
    call s:SparkupNext()
endfunction

function! s:SparkupNext()
    " 1: empty tag, 2: empty attribute, 3: empty line
    let n = search('><\/\|\(""\)\|^\s*$', 'Wp')
    if n == 3
        startinsert!
    else
        execute 'normal l'
        startinsert
    endif
endfunction
