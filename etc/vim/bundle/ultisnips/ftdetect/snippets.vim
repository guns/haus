" recognize .snippet files
if has("autocmd") && has("g:UltiSnipsLoaded")
    autocmd BufNewFile,BufRead *.snippets setf snippets
endif
