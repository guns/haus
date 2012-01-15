" Conventions:
"
" Super
"   Modifies / Toggles windows and tabs
"   Write buffers
"   Should not override OS / WM bindings
"
" Meta
"   Emacs style Movement / Editing
"
" <Leader>
"   Buffer settings (toggles, etc)
"   Opens :command line
"
" --/++
"   Show what builtin mappings are being overridden,
"   and what builtin mappings it is introducing


""" Preservations {{{1

" -- i_Ctrl-T (insert mode shift right)
" ++ i_Ctrl-X (insert mode completions)
PreserveMap! <C-t> <C-x>

" ++ Ctrl-X, Ctrl-A (decrement, increment)
PreserveMap <C-x>> <C-x>
PreserveMap <C-x>< <C-a>

" -- i_Ctrl-\ (mode switch)
" ++ i_Ctrl-K (insert digraph)
PreserveMap! <C-Bslash> <C-k>

" ++ Ctrl-y Ctrl-e (scroll window one line)
PreserveMap <4-e> <C-e>
PreserveMap <4-y> <C-y>

" -- , (repeat f, t backwards)
" ++ ; (repeat f, t)
PreserveMap , ;


""" Metamappings {{{1

" Mapleader:
"   * -- i_Ctrl-X (insert mode completions)
"   * breaks out of insert mode for universal availability
let g:mapleader = ''
map! <C-x> <Esc><Leader>

" Local Mapleader:
"   * -- - (previous line, first non-WS character)
let g:maplocalleader = '-'
map - <NOP>

" Allow use of <C-c> to terminate visual block insertion
" and hellaciously break out of Select mode
vnoremap <C-c> <Esc>
snoremap <C-c> <Esc><C-c>


""" Editing / Movement like Emacs {{{1

" char left/right (insert only)
" -- i_Ctrl-B i_Ctrl-F
noremap! <C-b> <Left>
noremap! <C-f> <Right>

" Word movement, character search
Mapall   <M-b> <C-o> b
Mapall   <M-B> <C-o> F
cnoremap <M-b> <S-Left>
Mapall   <M-f> <C-o> w
Mapall   <M-F> <C-o> f
cnoremap <M-f> <S-Right>

" bol/eol
" -- Ctrl-A i_Ctrl-A Ctrl-E i_Ctrl-E
noremap  <C-a> ^
noremap! <C-a> <Esc>I
cnoremap <C-a> <Home>
noremap  <C-e> $
noremap! <C-e> <Esc>A
cnoremap <C-e> <End>

" Rubout char / word / line
" -- Ctrl-U
noremap  <C-u>  d^
noremap  <M-BS> db
noremap! <M-BS> <C-w>

" Forward delete char / word / line
" FIXME: forward-delete-word creeps forward on command line
" -- Ctrl-D i_Ctrl-D c_Ctrl-K i_Ctrl-K
noremap  <C-d> x
noremap! <C-d> <Del>
Mapall   <M-d> <C-o> de
cnoremap <M-d> <S-Right><C-w>
Mapall   <C-k> <C-o> D
cnoremap <C-k> <C-n>

" Undo and enter normal mode
" -- Ctrl-_ i_Ctrl-_
Mapall   <C-_> u


""" Editing / Movement with modifiers {{{1

" Page up / down
" -- Ctrl-F Ctrl-B
noremap <C-f> <PageDown>M
noremap <C-b> <PageUp>M

" Soft-wrapped up and down
Mapall   <Up>   <C-o> gk
cnoremap <Up>   <Up>
Mapall   <Down> <C-o> gj
cnoremap <Down> <Down>


""" Command line / Search shortcuts {{{1

" -- ;
noremap ;          :
noremap /          /\v
noremap ?          ?\v
noremap <Bslash>   /\V
noremap <Bar>      ?\V
Mapall  <4-;>      q:
noremap q<Bslash>  q/
noremap <Leader>h  :help<Space>
noremap <Leader>co :colorscheme<Space>

" Overload redraw mapping to also clear last match
noremap <C-l> :let @/ = ''<CR>:redraw!<CR>

" Settings
noremap <Leader>s<Space> :setlocal<Space>
noremap <Leader>sc       :setlocal clipboard=unnamedplus
noremap <Leader>?sc      :set clipboard?<CR>
noremap <Leader>sf       :setlocal foldmethod=manual
noremap <Leader>?sf      :set foldmethod?<CR>
noremap <Leader>sm       :setlocal synmaxcol=1000
noremap <Leader>?sm      :set synmaxcol?<CR>
noremap <Leader>st       :SetTextwidth<Space>
noremap <Leader>?st      :SetTextwidth<CR>
noremap <Leader>sw       :SetWhitespace<Space>
noremap <Leader>?sw      :SetWhitespace<CR>

" Toggles
noremap <Leader>~     :setlocal spell!<CR>:setlocal spell?<CR>
noremap <Leader>sa?   :SetAutowrap<CR>
noremap <Leader><C-a> :SetAutowrap!<CR>
noremap <Leader><C-b> :setlocal scrollbind!<CR>:setlocal scrollbind?<CR>
noremap <Leader><C-e> :set expandtab!<CR>:set expandtab?<CR>
noremap <Leader><C-h> :set hlsearch!<CR>:set hlsearch?<CR>
noremap <Leader><C-l> :setlocal list!<CR>:setlocal list?<CR>
noremap <Leader><C-o> :set cursorline!<CR>:set cursorline?<CR>
noremap <Leader><C-p> :set paste!<CR>:set paste?<CR>
noremap <Leader><C-w> :setlocal wrap!<CR>:setlocal wrap?<CR>

" Other builtin commands
noremap <Leader>! :make!<CR>

" TextMate style syntax inspection
noremap <4-P> :SynStack<CR>

" Ctags
noremap <Leader><C-t> :Ctags<CR>:redraw!<CR>:echo 'Ctags'<CR>

" Terminal escapes
noremap <Nul>h :silent! ! xecho left<CR>:redraw!<CR>
noremap <Nul>l :silent! ! xecho right<CR>:redraw!<CR>
noremap <Nul>j :silent! ! xecho center<CR>:redraw!<CR>

" Plugin: Fugitive (git) + Gitv - remember to update readline macros
noremap <Leader>g<Space> :Git<Space>
noremap <Leader>gc       :Gcommit<CR>
noremap <Leader>gd       :Git di<CR>
noremap <Leader>g%       :Git di %<CR>
noremap <Leader>gf       :silent! Git f<CR>
noremap <Leader>gl       :silent! Git lp<CR>
noremap <Leader>gL       :Glog<CR>
noremap <Leader>gr       :silent! Git rs<CR>
noremap <Leader>gv       :Gitv<CR>
noremap <Leader>gV       :Gitv!<CR>
noremap <Leader>gaa      :silent! Git aa<CR>:echo 'All files added to index'<CR>
noremap <Leader>gac      :Git aa<CR>:Gcommit<CR>
noremap <Leader>gap      :Git ap<CR>
noremap <Leader><C-g>    :Gstatus<CR>
noremap <4-g>            :Gstatus<CR>
noremap <4-G>            q:iGgrep! -Pi<Space>


""" Window / Tab Management {{{1

" window focus / position
Mapall <4-Left>  :wincmd\ h<CR> | Mapall <4-S-Left>  :wincmd\ H<CR>
Mapall <4-Down>  :wincmd\ j<CR> | Mapall <4-S-Down>  :wincmd\ J<CR>
Mapall <4-Up>    :wincmd\ k<CR> | Mapall <4-S-Up>    :wincmd\ K<CR>
Mapall <4-Right> :wincmd\ l<CR> | Mapall <4-S-Right> :wincmd\ L<CR>
Mapall <4-h>     :wincmd\ h<CR> | Mapall <4-H>       :wincmd\ H<CR>
Mapall <4-j>     :wincmd\ j<CR> | Mapall <4-J>       :wincmd\ J<CR>
Mapall <4-k>     :wincmd\ k<CR> | Mapall <4-K>       :wincmd\ K<CR>
Mapall <4-l>     :wincmd\ l<CR> | Mapall <4-L>       :wincmd\ L<CR>

" Window capturing
Mapall  <4-O>  :execute\ winnr('$')\ ==\ 1\ ?\ 'tabonly'\ :\ 'only'<CR>
noremap <C-w>! :wincmd T<CR>
noremap <C-w>@ :CapturePane<CR>

" Tabs
Mapall  <4-t> :tabnew<CR>
Mapall  <4-T> :tabnew<CR>
Mapall  <4-{> :tabprevious<CR>
Mapall  <4-}> :tabnext<CR>
Mapall  <4-_> :execute\ 'tabmove\ '.(tabpagenr()-2)<CR>
Mapall  <4-+> :execute\ 'tabmove\ '.tabpagenr()<CR>

" Quickfix window
Mapall <4-x> :copen<CR>

" Plugin: Command-T
Mapall  <4-o> :CommandT<CR>
Mapall  <4-'> :CommandTJump<CR>
Mapall  <4-b> :CommandTBuffer<CR>
Mapall  <4-t> :tabnew<CR>:CommandT<CR>
noremap <4-B> :CommandTFlush<CR>:echo 'Command-T flushed!'<CR>

" Plugin: NERDTree
Mapall <4-d> :NERDTreeToggle<CR>
Mapall <4-D> :NERDTreeFind<CR>

" Plugin: Ack.vim
Mapall <4-A> q:iAck!<Space>

" Plugin: Gundo
Mapall <4-u> :GundoToggle<CR>

" Plugin: Regbuf
Mapall <4-r> :RegbufOpen<CR>

" Plugin: Preview
Mapall <4-p> :Preview<CR>

" Plugin: Open URLs and files
Mapall <4-U> :Open<CR>

" Plugin: ScreenShell
noremap <Leader>S :Screen<CR>

" Plugin: UltiSnips
noremap <4-F> :UltiSnipsEdit<CR>

" Plugin: Tagbar
Mapall <4-i> :TagbarToggle<CR>
Mapall <4-I> :TagbarOpen<CR>

" Plugin: Manpageview
noremap <Leader>K viwK
noremap <Leader>m :Man<Space>
noremap <Leader>M :VMan<Space>

" Plugin: NrrwRgn
nnoremap <Leader>nr vip:NarrowRegion<CR>


""" Buffer commands {{{1

" Open Files
noremap <Leader>e<Space> :tabedit<Space>
noremap <Leader>ea       :execute 'tabedit ' . expand('~/.vim/local/autocommands.vim')<CR>
noremap <Leader>eb       :execute 'tabedit ' . expand('~/.bashrc')<CR>
noremap <Leader>ec       :execute 'tabedit ' . expand('~/.vim/local/commands.vim')<CR>
noremap <Leader>ee       :edit<CR>
noremap <Leader>ei       :execute 'tabedit ' . expand('~/.inputrc')<CR>
noremap <Leader>el       :execute 'tabedit ' . expand('~/.bashrc.d/local.bash')<CR>
noremap <Leader>em       :execute 'tabedit ' . expand('~/.vim/local/mappings.vim')<CR>
noremap <Leader>en       :tabedit /opt/nginx/etc/nginx.conf<CR>
noremap <Leader>eo       :Org<CR>
noremap <Leader>er       :tabedit /etc/rc.conf<CR>
noremap <Leader>es       :tabnew<CR>:Scratch<CR>
noremap <Leader>eS       :vnew<CR>:wincmd L<CR>:Scratch<CR>
noremap <Leader>et       :Org TODO<CR>
noremap <Leader>ev       :execute 'tabedit ' . expand($MYVIMRC)<CR>
noremap <Leader>ew       :execute 'tabedit ' . expand('~/.config/subtle/subtle.rb')<CR>

" Set Filetypes
noremap <Leader>f<Space> :setlocal filetype=
noremap <Leader>f?       :setlocal filetype?<CR>
noremap <Leader>fb       :setlocal filetype=sh<CR>
noremap <Leader>fc       :setlocal filetype=c<CR>
noremap <Leader>fC       :setlocal filetype=clojure<CR>
noremap <Leader>fd       :setlocal filetype=diff<CR>
noremap <Leader>fh       :setlocal filetype=html<CR>
noremap <Leader>fj       :setlocal filetype=javascript<CR>
noremap <Leader>fm       :setlocal filetype=markdown<CR>
noremap <Leader>fM       :setlocal filetype=mail<CR>
noremap <Leader>fo       :setlocal filetype=org<CR>
noremap <Leader>fp       :setlocal filetype=plain<CR>
noremap <Leader>fr       :setlocal filetype=ruby<CR>
noremap <Leader>fs       :setlocal filetype=sh<CR>
noremap <Leader>fv       :setlocal filetype=vim<CR>
noremap <Leader>fy       :setlocal filetype=yaml<CR>
" Plugin: Shebang
noremap <Leader>fx       :silent! call SetExecutable()<CR>:redraw!<CR>

" Save / Exit
" -- Q
Mapall  <4-s>      :update<CR>
Mapall  <4-S>      :w\ !sudo\ tee\ %\ >/dev/null<CR>
noremap Q          :q<CR>
Mapall  <4-Bslash> :q<CR>
Mapall  <4-Bar>    :q!<CR>

" Reload files
noremap <Leader><C-r>
    \ :source ~/.vim/local/mappings.vim<CR>
    \ :source ~/.vim/local/commands.vim<CR>
    \ :echo 'Mappings and Commands reloaded!'<CR>
noremap <Leader>r :RunCurrentFile<CR>
noremap <Leader>R :RunCurrentMiniTestCase<CR>


""" Text editing {{{1

" Map readline's Unicode character bindings
MapReadlineUnicodeBindings

" Character macros
noremap  <M-CR> i\n<Esc><Right>
noremap! <M-CR> \n
noremap  <4-CR> A;<Esc>
noremap! <4-CR> <C-o>A;

" Center on next match
nnoremap n nzz
nnoremap N Nzz

" Change case
noremap  <M-u> guWW
noremap! <M-u> <C-o>guW<C-o>W
noremap  <M-U> gUWW
noremap! <M-U> <C-o>gUW<C-o>W

" Join lines
Mapall <Leader><C-j> <C-o> J

" Select all
noremap <4-a> maggVG

" Kill trailing whitespace
noremap <Leader><C-k> :let b:_reg_slash = @/<CR>m`:%s/[ \t\r]\+$//e<CR>:let @/ = b:_reg_slash<CR>:unlet b:_reg_slash<CR>``

" Hashrocket
noremap! <C-l> <Space>=><Space>

" Indent lines a la TextMate
nnoremap <4-[> <<
nnoremap <4-]> >>
inoremap <4-[> <C-o><<
inoremap <4-]> <C-o>>>
vnoremap <4-[> <gv
vnoremap <4-]> >gv

" Wrap / break parens (useful for Lisp forms)
Mapall <Leader>ab :normal\ %vabyvababpm`=ap``<CR>
Mapall <Leader>ib :normal\ ysib(<CR>i

" http://vim.wikia.com/wiki/Moving_lines_up_or_down
nnoremap <M-j> :m+<CR>==
nnoremap <M-k> :m-2<CR>==
inoremap <M-j> <Esc>:m+<CR>==gi
inoremap <M-k> <Esc>:m-2<CR>==gi
vnoremap <M-j> :m'>+<CR>gv=gv
vnoremap <M-k> :m-2<CR>gv=gv

" http://vim.wikia.com/wiki/Drag_words_with_Ctrl-left/right
vnoremap <M-h> <Esc>`<<Left>i_<Esc>mz"_xgvx`zPgv<Left>o<Left>o
vnoremap <M-l> <Esc>`><Right>gvxpgv<Right>o<Right>o

" Add numbers in selection
" -- +
vnoremap + "ry:ruby
    \ r = VIM.evaluate('@r').scan(/(\d+(\.\d+)?)/).flatten.map(&:to_f).inject(:+);
    \ VIM.command(%q(let @r = "%s") % r);
    \ print r<CR>

" Plugin: surround.vim - visual surround shortcuts (a la TextMate)
" -- ( '
vmap ( s(
vmap ' s'

" Plugin: Align
noremap <Leader>a<Space> :Align<Space>
noremap <Leader>a.       :Align \.<CR>
noremap <Leader>a<C-l>   :Align =><CR>

" Plugin: operator-camelize
nmap <Leader>_ viw<Plug>(operator-camelize-toggle)
vmap <Leader>_ <Plug>(operator-camelize-toggle)

" Plugin: NERD_commenter (assigning to <plug> via Mapall doesn't seem to work)
map  <4-/> <Plug>NERDCommenterToggleAlign
map! <4-/> <Esc><Plug>NERDCommenterToggleAlign

" Plugin: closetag
noremap! <4-.> <C-r>=GetCloseTag()<CR>
noremap  <4-.> a<C-r>=GetCloseTag()<CR><Esc>
