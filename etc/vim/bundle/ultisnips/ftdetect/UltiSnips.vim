" This has to be called before ftplugins are loaded. Therefore
" it is here in ftdetect though it maybe shouldn't
if has("autocmd") && (has("python") || has("python3"))
   augroup UltiSnipsFileType
      au!
      autocmd FileType * call UltiSnips#FileTypeChanged()
   augroup END
endif
