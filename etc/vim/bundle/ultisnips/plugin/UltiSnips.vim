if exists('did_plugin_ultisnips') || &cp
    finish
elseif !(has('python3') || has('python'))
    let did_UltiSnips_plugin=1
    finish
endif
let did_plugin_ultisnips=1

if version < 704
   echohl WarningMsg
   echom  "UltiSnips requires Vim >= 7.4"
   echohl None
   finish
endif

" The Commands we define.
command! -bang -nargs=? -complete=customlist,UltiSnips#FileTypeComplete UltiSnipsEdit
    \ :call UltiSnips#Edit(<q-bang>, <q-args>)

command! -nargs=1 UltiSnipsAddFiletypes :call UltiSnips#AddFiletypes(<q-args>)

augroup UltiSnips_AutoTrigger
    au!
augroup END

call UltiSnips#map_keys#MapKeys()

" vim: ts=8 sts=4 sw=4
