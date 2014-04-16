" DrawItPlugin.vim: a simple way to draw things in Vim -- just put this file in
"             your plugin directory, use \di to start (\ds to stop), and
"             just move about using the cursor keys.
"
"             You may also use visual-block mode to select endpoints and
"             draw lines, arrows, and ellipses.
"
" Date:			Nov 28, 2012
" Maintainer:	Charles E. Campbell  <NdrOchipS@PcampbellAfamily.Mbiz>
" Copyright:    Copyright (C) 1999-2012 Charles E. Campbell {{{1
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               DrawIt.vim is provided *as is* and comes with no warranty
"               of any kind, either expressed or implied. By using this
"               plugin, you agree that in no event will the copyright
"               holder be liable for any damages resulting from the use
"               of this software.
"
" Required:  this script requires Vim 7.0 (or later) {{{1
" To Enable: simply put this plugin into your ~/.vim/plugin directory {{{2
"
" GetLatestVimScripts: 40 1 :AutoInstall: DrawIt.vim
"
"  (Zeph 3:1,2 WEB) Woe to her who is rebellious and polluted, the {{{1
"  oppressing city! She didn't obey the voice. She didn't receive
"  correction.  She didn't trust in Yahweh. She didn't draw near to her God.

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_DrawItPlugin")
 finish
endif
let g:loaded_DrawItPlugin = "v14b"
let s:keepcpo             = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Public Interface: {{{1
" commands:
" com! -nargs=0 -bang DrawIt   	if <bang>0|call DrawIt#DrawItStop()|else|call DrawIt#DrawItStart()|endif
" com! -nargs=?       DIstart  	call DrawIt#DrawItStart(<q-args>)
" com! -nargs=0       DIstop   	call DrawIt#DrawItStop()

" commands: available only when not pre-defined
sil! com -nargs=0 Drawascii  call DrawIt#SetMode('N')
sil! com -nargs=0 Drawsingle call DrawIt#SetMode('S')
sil! com -nargs=0 Drawdouble call DrawIt#SetMode('D')
sil! com -nargs=0 Drawdashed call DrawIt#SetMode('dashed')

" maps: users may override these maps by defining their own mappings in their .vimrc
"       to <Plug>DrawItStart and/or <Plug>DrawItStop.  By default:
"         \di : start DrawIt
"         \ds : stop  DrawIt
" if !hasmapto('<Plug>DrawItStart')
"   map <unique> <Leader>di <Plug>DrawItStart
" endif
" noremap <silent>        <Plug>DrawItStart  :call DrawIt#DrawItStart()<cr>
" if !hasmapto('<Plug>DrawItStop')
"   map <unique> <Leader>ds <Plug>DrawItStop
" endif
" noremap <silent> <Plug>DrawItStop :call DrawIt#DrawItStop()<cr>

" ---------------------------------------------------------------------
" DrChip Menu Support: {{{1
if has("gui_running") && has("menu") && &go =~# 'm'
 if !exists("g:DrChipTopLvlMenu")
  let g:DrChipTopLvlMenu= "DrChip."
 endif
 exe 'menu '.g:DrChipTopLvlMenu.'DrawIt.Start\ DrawIt<tab>\\di		<Leader>di'
endif

" ---------------------------------------------------------------------
"  Cleanup And Modelines:
"  vim: fdm=marker
let &cpo= s:keepcpo
unlet s:keepcpo
