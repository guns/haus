" Called after everything else to reclaim keys (Needed for Supertab)

if exists("b:did_after_plugin_ultisnips_after") || !exists("g:_uspy")
   finish
elseif !(has('python') || has('python3'))
    let did_UltiSnips_after=1
    finish
endif
let b:did_after_plugin_ultisnips_after = 1

call UltiSnips#map_keys#MapKeys()
