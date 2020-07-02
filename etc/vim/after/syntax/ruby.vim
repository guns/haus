"
" Ruby SQL heredoc syntax highlighting
"

let s:bcs = b:current_syntax
unlet b:current_syntax
syn include @SQL syntax/pgsql.vim
let b:current_syntax = s:bcs
syntax region rubyHereDocSQL matchgroup=Statement start=+<<\z(SQL\)+ end=+^\z1$+ contains=@SQL
syntax region rubyHereDocDashSQL matchgroup=Statement start=+<<[~-]\z(SQL\)+ end=+\s\+\z1$+ contains=@SQL
