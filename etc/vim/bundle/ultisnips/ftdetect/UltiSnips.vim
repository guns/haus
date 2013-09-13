" This has to be called before ftplugins are loaded. Therefore 
" it is here in ftdetect though it maybe shouldn't
if has("autocmd") && (has("python") || has("python3"))
   autocmd FileType * call UltiSnips_FileTypeChanged()
endif

