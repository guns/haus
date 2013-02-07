" manpagevim : extra commands for manual-handling
" Author:	Charles E. Campbell, Jr.
" Date:		Nov 02, 2012
" Version:	25b	ASTRO-ONLY
"
" Please read :help manpageview for usage, options, etc
"
" GetLatestVimScripts: 489 1 :AutoInstall: manpageview.vim

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_manpageview")
 finish
endif
let g:loaded_manpageview = "v25b"
if v:version < 702
 echohl WarningMsg
 echo "***warning*** this version of manpageview needs vim 7.2 or later"
 echohl Normal
 finish
endif
let s:keepcpo= &cpo
set cpo&vim
"DechoTabOn

" ---------------------------------------------------------------------
" Set up default manual-window opening option: {{{1
if !exists("g:manpageview_winopen")
 let g:manpageview_winopen= "hsplit"
elseif g:manpageview_winopen == "only" && !has("mksession")
 echomsg "***g:manpageview_winopen<".g:manpageview_winopen."> not supported w/o +mksession"
 let g:manpageview_winopen= "hsplit"
endif

" ---------------------------------------------------------------------
" Sanity Check: {{{1
if !exists("*shellescape")
 fun! manpageview#ManPageView(viamap,bknum,...) range
   echohl ERROR
   echo "You need to upgrade your vim to v7.1 or later (manpageview uses the shellescape() function)"
 endfun
 finish
endif

" ---------------------------------------------------------------------
" Default Variable Values: {{{1
if !exists("g:manpageview_iconv")
 if executable("iconv")
  let s:iconv= "iconv -c"
 else
  let s:iconv= ""
 endif
else
 let s:iconv= g:manpageview_iconv
endif
if s:iconv != ""
 let s:iconv= "| ".s:iconv
endif
if !exists("g:manpageview_pgm") && executable("man")
 let g:manpageview_pgm= "man"
endif
if !exists("g:manpageview_multimanpage")
 let g:manpageview_multimanpage= 1
endif
if !exists("g:manpageview_options")
 let g:manpageview_options= ""
endif
if !exists("g:manpageview_pgm_i") && executable("info")
" DechoWF "installed info help support via manpageview"
 let g:manpageview_pgm_i     = "info"
 let g:manpageview_options_i = "--output=-"
 let g:manpageview_syntax_i  = "info"
 let g:manpageview_K_i       = "<sid>ManPageInfo(0)"
 let g:manpageview_init_i    = "call ManPageInfoInit()"

 let s:linkpat1 = '\*[Nn]ote \([^():]*\)\(::\|$\)' " note
 let s:linkpat2 = '^\* [^:]*: \(([^)]*)\)'         " filename
 let s:linkpat3 = '^\* \([^:]*\)::'                " menu
 let s:linkpat4 = '^\* [^:]*:\s*\([^.]*\)\.$'      " index
endif
if !exists("g:manpageview_pgm_pl") && executable("perldoc")
" DechoWF "installed perl help support via manpageview"
 let g:manpageview_pgm_pl     = "perldoc"
 let g:manpageview_options_pl = ";-f;-q"
endif
if !exists("g:manpageview_pgm_php") && (executable("links") || executable("elinks"))
"  DechoWF "installed php help support via manpageview"
 let g:manpageview_pgm_php     = (executable("links")? "links" : "elinks")." -dump http://www.php.net/"
 let g:manpageview_syntax_php  = "manphp"
 let g:manpageview_nospace_php = 1
 let g:manpageview_K_php       = "manpageview#ManPagePhp()"
endif
if !exists("g:manpageview_pgm_gl") && (executable("links") || executable("elinks"))
 let g:manpageview_pgm_gl     = (executable("links")? "links" : "elinks")." -dump http://www.opengl.org/sdk/docs/man/xhtml/"
 let g:manpageview_syntax_gl  = "mangl"
 let g:manpageview_nospace_gl = 1
 let g:manpageview_K_gl       = "manpageview#ManPagePhp()"
 let g:manpageview_sfx_gl     = ".xml"
endif
if !exists("g:manpageview_pgm_py") && executable("pydoc")
" DechoWF "installed python help support via manpageview"
 let g:manpageview_pgm_py     = "pydoc"
 let g:manpageview_K_py       = "manpageview#ManPagePython()"
endif
if exists("g:manpageview_hypertext_tex") && !exists("g:manpageview_pgm_tex") && (executable("links") || executable("elinks"))
" DechoWF "installed tex help support via manpageview"
 let g:manpageview_pgm_tex    = (executable("links")? "links" : "elinks")." ".g:manpageview_hypertext_tex
 let g:manpageview_lookup_tex = "manpageview#ManPageTexLookup"
 let g:manpageview_K_tex      = "manpageview#ManPageTex()"
endif
if has("win32") && !exists("g:manpageview_rsh")
" DechoWF "installed rsh help support via manpageview"
 let g:manpageview_rsh= "rsh"
endif

" =====================================================================
"  Functions: {{{1

" ---------------------------------------------------------------------
" manpageview#ManPageView: view a manual-page, accepts three formats: {{{2
"    :call manpageview#ManPageView(viamap,"topic")
"    :call manpageview#ManPageView(viamap,booknumber,"topic")
"    :call manpageview#ManPageView(viamap,"topic(booknumber)")
"
"    viamap=0: called via a command
"    viamap=1: called via a map
"    bknum   : if non-zero, then its the book number of the manpage (default=1)
"              if zero, but viamap==1, then use lastline-firstline+1
fun! manpageview#ManPageView(viamap,bknum,...) range
"  call Dfunc("manpageview#ManPageView(viamap=".a:viamap." bknum=".a:bknum.") a:0=".a:0. " version=".g:loaded_manpageview)
  set lz
  let manpageview_fname = expand("%")
  let bknum             = a:bknum
  call s:MPVSaveSettings()
"  if exists("g:manpageview_winopen")|call Decho("g:manpageview_winopen<".g:manpageview_winopen.">")|endif

  " fix topic {{{3
  if a:0 > 0
"   DechoWF "(fix topic) case a:0 > 0: (a:1<".a:1.">)"
   if &ft != "info"
	if a:0 == 2 && bknum > 0
	 let bknum = bknum.a:1
	 let topic = a:2
	else
     let topic= substitute(a:1,'[^-a-zA-Z.0-9_:].*$','','')
"     DechoWF "a:1<".a:1."> topic<".topic."> (after fix)"
	endif
   else
   	let topic= a:1
   endif
   if topic =~ '($'
    let topic= substitute(topic,'($','','')
   endif
"   DechoWF "topic<".topic.">  bknum=".bknum." (after fix topic)"
  endif

  if !exists("topic") || topic == ""
   echohl WarningMsg
   echo "***warning*** missing topic"
   echohl None
"   call Dret("manpageview#ManPageView : missing topic")
   return
  endif

  " interpret the input arguments - set up manpagetopic and manpagebook {{{3
  if a:0 > 0 && strpart(topic,0,1) == '"'
"   DechoWF "(interpret input arguments) topic<".topic.">"
   " merge quoted arguments:  Man "some topic here"
"   DechoWF '(merge quoted args) case a:0='.a:0." strpart(".topic.",0,1)<".strpart(topic,0,1)
   let manpagetopic = strpart(topic,1)
   if manpagetopic =~ '($'
    let manpagetopic= substitute(manpagetopic,'($','','')
   endif
"   DechoWF "manpagetopic<".manpagetopic.">"
   if bknum != ""
   	let manpagebook= string(bknum)
   else
    let manpagebook= ""
   endif
"   DechoWF "manpagebook<".manpagebook.">"
   let i= 2
   while i <= a:0
   	let manpagetopic= manpagetopic.' '.a:{i}
	if a:{i} =~ '"$'
	 break
	endif
   	let i= i + 1
   endwhile
   let manpagetopic= strpart(manpagetopic,0,strlen(manpagetopic)-1)
"   DechoWF "merged quoted arguments<".manpagetopic.">"

  elseif a:0 == 0
"   DechoWF 'case a:0==0'
   if exists("g:ManCurPosn") && has("mksession")
"    DechoWF "(ManPageView) a:0=".a:0."  g:ManCurPosn exists"
	call s:ManRestorePosn()
   else
    echomsg "***usage*** :Man topic  -or-  :Man topic nmbr"
"    DechoWF "(ManPageView) a:0=".a:0."  g:ManCurPosn doesn't exist"
   endif
   call s:MPVRestoreSettings()
"   call Dret("manpageview#ManPageView")
   return

  elseif a:0 == 1
   " ManPageView("topic") -or-  ManPageView("topic(booknumber)")
"   DechoWF "case a:0==1 (topic  -or-  topic(booknumber))"
"   DechoWF "(ManPageView) a:0=".a:0." topic<".topic.">"
   if a:1 =~ "("
    " ManPageView("topic(booknumber)")
"	DechoWF "a:1<".a:1."> has parenthesis: ft<".&ft."> (may be topic(booknumber) )"
	let a1 = substitute(a:1,'[-+*/;,.:]\+$','','e')
"	DechoWF "has parenthesis: a:1<".a:1.">  a1<".a1.">"
	if &ft == 'sh'
"	 DechoWF "case ft=".&ft.": has parenthesis: but ft isn't <man>"
	 let manpagetopic = substitute(a:1,'(.*$','','')
	 let manpagebook  = ""
	elseif &ft != 'man'
"	 DechoWF "case ft=".&ft.": has parenthesis: but ft isn't <man>"
	 let manpagetopic = substitute(a:1,'(.*$','','')
	 if a:viamap == 0
	  " called via a command
      let manpagebook = substitute(a1,'^.*(\([^)]\+\))\=.*$','\1','e')
	 else
	  " called via a map
	  let manpagebook = "3"
"	  DechoWF "(ManPageView) case ft=".&ft.": setting manpagebook to ".manpagebook
	 endif
    elseif a1 =~ '[,"]'
"	 DechoWF "case ft=".&ft." and a1=".a1.": has parenthesis: a:1 matches [,"]'
     let manpagetopic= substitute(a1,'[(,"].*$','','e')
	else
"	 DechoWF "case ft=".&ft." and a1=".a1.": has parenthesis: a:1 does not match [,"]'
     let manpagetopic= substitute(a1,'^\(.*\)(\d\w*),\=.*$','\1','e')
     let manpagebook = substitute(a1,'^.*(\(\d\w*\)),\=.*$','\1','e')
	endif
    if manpagetopic =~ '($'
"	 DechoWF 'has parenthesis: manpagetopic<'.a:1.'> matches "($"'
     let manpagetopic= substitute(manpagetopic,'($','','')
    endif
    if manpagebook =~ '($'
"	 DechoWF 'has parenthesis: manpagebook<'.manpagebook.'> matches "($"'
     let manpagebook= ""
    endif
	if manpagebook =~ '\d\+\a\+'
	 let manpagebook= substitute(manpagebook,'\a\+','','')
	endif

   else
    " ManPageView(booknumber,"topic")
"	DechoWF '(ManPageView(booknumber,"topic")) case a:0='.a:0
    let manpagetopic= topic
    if a:viamap == 1 && a:lastline > a:firstline
     let manpagebook= string(a:lastline - a:firstline + 1)
    elseif a:bknum > 0
     let manpagebook= string(a:bknum)
	else
     let manpagebook= ""
    endif
   endif

  else
   " 3 abc  -or-  abc 3
"   DechoWF "(3 abc -or- abc 3) case a:0=".a:0
   if     topic =~ '^\d\+'
"	DechoWF "case 1: topic =~ ^\d\+"
    let manpagebook = topic
    let manpagetopic= a:2
   elseif a:2 =~ '^\d\+$'
"	DechoWF "case 2: topic =~ \d\+$"
    let manpagebook = a:2
    let manpagetopic= topic
   elseif topic == "-k"
"	DechoWF "case 3: topic == -k"
"    DechoWF "user requested man -k"
    let manpagetopic = a:2
    let manpagebook  = "-k"
   elseif bknum != ""
"	DechoWF 'case 4: bknum != ""'
	let manpagetopic = topic
	let manpagebook  = bknum
   else
	" default: topic book
"	DechoWF "default case: topic book"
    let manpagebook = a:2
    let manpagetopic= topic
   endif
  endif
"  DechoWF "manpagetopic<".manpagetopic.">"
"  DechoWF "manpagebook <".manpagebook.">"

  " for the benefit of associated routines (such as InfoIndexLink()) {{{3
  let s:manpagetopic = manpagetopic
  let s:manpagebook  = manpagebook

  " default program g:manpageview_pgm=="man" may be overridden {{{3
  " if an extension is matched
  if exists("g:manpageview_pgm")
   let pgm = g:manpageview_pgm
  else
   let pgm = ""
  endif
  let ext = ""
  if manpagetopic =~ '\.'
   let ext = substitute(manpagetopic,'^.*\.','','e')
  endif
  if exists("g:manpageview_pgm_gl") && manpagetopic =~ '^gl'
	  let ext = "gl"
  endif

  " infer the appropriate extension based on the filetype {{{3
  if ext == ""
"   DechoWF "attempt to infer on filetype<".&ft.">"

   " filetype: perl
   if &ft == "perl" || &ft == "perldoc"
   	let ext = "pl"

   " filetype:  php
   elseif &ft == "php" || &ft == "manphp"
   	let ext = "php"

	" filetype:  python
   elseif &ft == "python" || &ft == "pydoc"
   	let ext = "py"

   " filetype: tex
  elseif &ft == "tex"
   let ext= "tex"
   endif

  endif
"  DechoWF "ext<".ext.">"

  " elide extension from manpagetopic {{{3
  if exists("g:manpageview_pgm_{ext}")
   let pgm          = g:manpageview_pgm_{ext}
   let manpagetopic = substitute(manpagetopic,'.'.ext.'$','','')
  endif
  let nospace= exists("g:manpageview_nospace_{ext}")? g:manpageview_nospace_{ext} : 0
"  DechoWF "pgm<".pgm."> manpagetopic<".manpagetopic.">  (after elision of extension)"

  " special exceptions:
  if ext =~ 'man'
   " for man: allow ".man" extension to mean we want regular manpages even while in a supported filetype
   let pgm          = ext
   let manpagetopic = substitute(manpagetopic,'.'.ext.'$','','')
   let ext          = ""
  elseif a:viamap == 0 && ext == "i"
  " special exception for info {{{3
   let s:manpageview_pfx_i = "(".manpagetopic.")"
   let manpagetopic        = "Top"
"   DechoWF "top-level info: manpagetopic<".manpagetopic.">"
  endif

  if exists("s:manpageview_pfx_{ext}") && s:manpageview_pfx_{ext} != ""
   let manpagetopic= s:manpageview_pfx_{ext}.manpagetopic
  elseif exists("g:manpageview_pfx_{ext}") && g:manpageview_pfx_{ext} != ""
   " prepend any extension-specified prefix to manpagetopic
   let manpagetopic= g:manpageview_pfx_{ext}.manpagetopic
  endif

  if exists("g:manpageview_sfx_{ext}") && g:manpageview_sfx_{ext} != ""
   " append any extension-specified suffix to manpagetopic
   let manpagetopic= manpagetopic.g:manpageview_sfx_{ext}
  endif

  if exists("g:manpageview_K_{ext}") && g:manpageview_K_{ext} != ""
   " override usual K map
"   DechoWF "change K map to call ".g:manpageview_K_{ext}
   exe "nmap <silent> K :call ".g:manpageview_K_{ext}."\<cr>"
  endif

  if exists("g:manpageview_syntax_{ext}") && g:manpageview_syntax_{ext} != ""
   " allow special-suffix extensions to optionally control syntax highlighting
   let manpageview_syntax= g:manpageview_syntax_{ext}
  else
   let manpageview_syntax= "man"
  endif

  " it was reported to me that some systems change display sizes when a {{{3
  " filtering command is used such as :r! .  I record the height&width
  " here and restore it afterwards.  To make use of it, put
  "   let g:manpageview_dispresize= 1
  " into your <.vimrc>
  let dwidth  = &cwh
  let dheight = &co
"  DechoWF "dwidth=".dwidth." dheight=".dheight

  " Set up the window for the manpage display (only hsplit split etc) {{{3
"  DechoWF "set up window for manpage display (g:manpageview_winopen<".g:manpageview_winopen."> ft<".&ft."> manpageview_syntax<".manpageview_syntax.">)"
  if     g:manpageview_winopen == "only"
   " OMan
"   DechoWF "only mode"
   sil! noautocmd windo w
   if !exists("g:ManCurPosn") && has("mksession")
    call s:ManSavePosn()
   endif
   " Record current file/position/screen-position
   if &ft != manpageview_syntax
    sil! only!
   endif
   enew!

  elseif g:manpageview_winopen == "hsplit"
   " HMan
"   DechoWF "hsplit mode"
   if &ft != manpageview_syntax
    wincmd s
    enew!
    wincmd _
    3wincmd -
   else
    enew!
   endif

  elseif g:manpageview_winopen == "hsplit="
   " HEMan
"   DechoWF "hsplit= mode"
   if &ft != manpageview_syntax
    wincmd s
   endif
   enew!

  elseif g:manpageview_winopen == "vsplit"
   " VMan
"   DechoWF "vsplit mode"
   if &ft != manpageview_syntax
    wincmd v
    enew!
    wincmd |
    20wincmd <
   else
    enew!
   endif

  elseif g:manpageview_winopen == "vsplit="
   " VEMan
"   DechoWF "vsplit= mode"
   if &ft != "man"
    wincmd v
   endif
   enew!

  elseif g:manpageview_winopen == "tab"
   " TMan
"   DechoWF "tab mode"
   if &ft != "man"
    tabnew
   endif

  elseif g:manpageview_winopen == "reuse"
   " RMan
"   DechoWF "reuse mode"
   " determine if a Manpageview window already exists
   let g:manpageview_manwin= -1
   exe "noautocmd windo if &ft == '".fnameescape(manpageview_syntax)."'|let g:manpageview_manwin= winnr()|endif"
   if g:manpageview_manwin != -1
	" found a pre-existing Manpageview window, re-using it
	exe fnameescape(g:manpageview_manwin)."wincmd w"
    enew!
   elseif &l:mod == 1
   	" file has been modified, would be lost if we re-used window.  Use hsplit instead.
    wincmd s
    enew!
    wincmd _
    3wincmd -
   elseif &ft != manpageview_syntax
	" re-using current window (but hiding it first)
   	setlocal bh=hide
    enew!
   else
    enew!
   endif
  else
   echohl ErrorMsg
   echo "***sorry*** g:manpageview_winopen<".g:manpageview_winopen."> not supported"
   echohl None
   call s:MPVRestoreSettings()
"   call Dret("manpageview#ManPageView : manpageview_winopen<".g:manpageview_winopen."> not supported")
   return
  endif

  " let manpages format themselves to specified window width
  " this setting probably only affects the linux "man" command.
  let $MANWIDTH= winwidth(0)

  " add some maps for multiple manpage handling {{{3
  " (some manpages on some systems have multiple NAME... topics provided on a single manpage)
  " The code here has PageUp/Down typically do a ctrl-f, ctrl-b; however, if there are multiple
  " topics on the manpage, then PageUp/Down will go to the previous/succeeding topic, instead.
  if g:manpageview_multimanpage
   let swp      = SaveWinPosn(0)
   let nameline1 = search("^NAME$",'Ww')
   let nameline2 = search("^NAME$",'Ww')
   sil! call RestoreWinPosn(swp)
   if nameline1 != nameline2 && nameline1 >= 1 && nameline2 >= 1
"	DechoWF "mapping PageUp/Down to go to preceding/succeeding multimanpage-topic"
	nno <silent> <script> <buffer> <PageUp>			:call search("^NAME$",'bW')<cr>z<cr>5<c-y>
	nno <silent> <script> <buffer> <PageDown>		:call search("^NAME$",'W')<cr>z<cr>5<c-y>
   else
"	DechoWF "mapping PageUp/Down to go to ctrl-f, ctrl-b"
	nno <silent> <script> <buffer> <PageUp>			<c-f>
	nno <silent> <script> <buffer> <PageDown>		<c-b>
   endif
  else
"   DechoWF "mapping PageUp/Down to go to ctrl-f, ctrl-b"
   nno <silent> <script> <buffer> <PageUp>			<c-f>
   nno <silent> <script> <buffer> <PageDown>		<c-b>
  endif

  " allow K to use <cWORD> when in man pages
  if manpageview_syntax == "man"
"   DechoWF "change K map to allow <cWORD> in man pages"
   nmap <silent> <script> <buffer>	K   :<c-u>let g:mpv_before_k_posn= SaveWinPosn(0)<bar>call manpageview#ManPageView(1,v:count,expand("<cWORD>"))<CR>
  endif

  " allow user to specify file encoding {{{3
  if exists("g:manpageview_fenc")
   exe "setlocal fenc=".fnameescape(g:manpageview_fenc)
  endif

  " when this buffer is exited it will be wiped out {{{3
  if v:version >= 602
   setlocal bh=wipe
  endif
  let b:did_ftplugin= 2
  let $COLUMNS=winwidth(0)

  " special manpageview buffer maps {{{3
  nnoremap <buffer> <c-]>       :call manpageview#ManPageView(1,expand("<cWORD>"))<cr>

  " -----------------------------------------
  " Invoke the man command to get the manpage {{{3
  " -----------------------------------------

  " the buffer must be modifiable for the manpage to be loaded via :r! {{{4
  setlocal ma

  let cmdmod= ""
  if v:version >= 603
   let cmdmod= "silent keepjumps "
  endif

  " extension-based initialization (expected: buffer-specific maps) {{{4
  if exists("g:manpageview_init_{ext}")
   if !exists("b:manpageview_init_{ext}")
"    DechoWF "exe manpageview_init_".ext."<".g:manpageview_init_{ext}.">"
	exe g:manpageview_init_{ext}
	let b:manpageview_init_{ext}= 1
   endif
  elseif ext == ""
"   DechoWF "change K map to support empty extension"
   sil! unmap K
   nmap <unique> K <Plug>ManPageView
"   DechoWF "nmap <unique> K <Plug>ManPageView"
  endif

  " default program g:manpageview_options (empty string) may be overridden {{{4
  " if an extension is matched
  let opt= g:manpageview_options
  if exists("g:manpageview_options_{ext}")
   let opt= g:manpageview_options_{ext}
  endif
"  DechoWF "opt<".opt.">"

  let cnt= 0
  while cnt < 3 && (strlen(opt) > 0 || cnt == 0)
   let cnt   = cnt + 1
   let iopt  = substitute(opt,';.*$','','e')
   let opt   = substitute(opt,'^.\{-};\(.*\)$','\1','e')
"   DechoWF "cnt=".cnt." iopt<".iopt."> opt<".opt."> s:iconv<".(exists("s:iconv")? s:iconv : "").">"

   " use pgm to read/find/etc the manpage (but only if pgm is not the empty string)
   " by default, pgm is "man"
   if pgm != ""

	" ---------------------------
	" use manpage_lookup function {{{4
	" ---------------------------
   	if exists("g:manpageview_lookup_{ext}")
"	 DechoWF "lookup: exe call ".g:manpageview_lookup_{ext}."(".manpagebook.",".manpagetopic.")"
	 exe "call ".fnameescape(g:manpageview_lookup_{ext}."(".manpagebook.",".manpagetopic.")")

    elseif has("win32") && exists("g:manpageview_server") && exists("g:manpageview_user")
"     DechoWF "win32: manpagebook<".manpagebook."> topic<".manpagetopic.">"
     exe cmdmod."r!".g:manpageview_rsh." ".g:manpageview_server." -l ".g:manpageview_user." ".pgm." ".iopt." ".shellescape(manpagebook,1)." ".shellescape(manpagetopic,1)
     exe cmdmod.'sil!  %s/.\b//ge'

"   elseif has("conceal")
"    exe cmdmod."r!".pgm." ".iopt." ".shellescape(manpagebook,1)." ".shellescape(manpagetopic,1)

	"--------------------------
	" use pgm to obtain manpage {{{4
	"--------------------------
    else
	 if manpagebook != ""
	  let mpb= shellescape(manpagebook,1)
	 else
	  let mpb= ""
	 endif
     if nospace
"      DechoWF "(nospace) exe sil! ".cmdmod."r!".pgm.iopt.mpb.manpagetopic.s:iconv
	  exe cmdmod."r!".pgm.iopt.mpb.shellescape(manpagetopic,1).(exists("s:iconv")? s:iconv : "")
     elseif has("win32")
"	   DechoWF "(win32) exe ".cmdmod."r!".pgm." ".iopt." ".mpb." \"".manpagetopic."\" ".(exists("s:iconv")? s:iconv : "")
       exe cmdmod."r!".pgm." ".iopt." ".mpb." ".shellescape(manpagetopic,1).(exists("s:iconv")? " ".s:iconv : "")
	 else
"	  DechoWF "(nrml) exe ".cmdmod."r!".pgm." ".iopt." ".mpb." '".manpagetopic."' ".(exists("s:iconv")? s:iconv : "")
	  exe cmdmod."r!".pgm." ".iopt." ".mpb." ".shellescape(manpagetopic,1).(exists("s:iconv")? " ".s:iconv : "")
	endif
     exe cmdmod.'sil!  %s/.\b//ge'
    endif
	setlocal ro nomod noswf
   endif

   " check if manpage actually found {{{3
   if line("$") != 1 || col("$") != 1
"    DechoWF "manpage found"
    break
   endif
"   DechoWF "manpage not found"
   if cnt == 3 && !exists("g:manpageview_iconv") && s:iconv != ""
	let s:iconv= ""
"	DechoWF "trying with no iconv"
   endif
  endwhile

  " here comes the vim display size restoration {{{3
  if exists("g:manpageview_dispresize")
   if g:manpageview_dispresize == 1
"    DechoWF "restore display size to ".dheight."x".dwidth
    exe "let &co=".dwidth
    exe "let &cwh=".dheight
   endif
  endif

  " clean up (ie. remove) any ansi escape sequences {{{3
  sil! %s/\e\[[0-9;]\{-}m//ge
  sil! %s/\%xe2\%x80\%x90/-/ge
  sil! %s/\%xe2\%x88\%x92/-/ge
  sil! %s/\%xe2\%x80\%x99/'/ge
  sil! %s/\%xe2\%x94\%x82/ /ge

  " set up options and put cursor at top-left of manpage {{{3
  if manpagebook == "-k"
   setlocal ft=mankey
  else
   exe cmdmod."setlocal ft=".fnameescape(manpageview_syntax)
  endif
  exe cmdmod."setlocal ro"
  exe cmdmod."setlocal noma"
  exe cmdmod."setlocal nomod"
  exe cmdmod."setlocal nolist"
  exe cmdmod."setlocal nonu"
  exe cmdmod."setlocal fdc=0"
"  exe cmdmod."setlocal isk+=-,.,(,)"
  exe cmdmod."setlocal nowrap"
  set nolz
  exe cmdmod."1"
  exe cmdmod."norm! 0"

  if line("$") == 1 && col("$") == 1
   " looks like there's no help for this topic
   if &ft == manpageview_syntax
	if exists("s:manpageview_curtopic")
	 call manpageview#ManPageView(0,0,s:manpageview_curtopic)
	else
	 q
	endif
   endif
   call SaveWinPosn()
"   DechoWF "***warning*** no manpage exists for <".manpagetopic."> book=".manpagebook
   echohl ErrorMsg
   echo "***warning*** sorry, no manpage exists for <".manpagetopic.">"
   echohl None
   if exists("g:mpv_before_k_posn")
	sil! call RestoreWinPosn(g:mpv_before_k_posn)
	unlet g:mpv_before_k_posn
   endif
  elseif manpagebook == ""
"   DechoWF 'exe file '.fnameescape('Manpageview['.manpagetopic.']')
   exe 'file '.fnameescape('Manpageview['.manpagetopic.']')
   let s:manpageview_curtopic= manpagetopic
  else
"   DechoWF 'exe file '.fnameescape('Manpageview['.manpagetopic.'('.fnameescape(manpagebook).')]')
   exe 'file '.fnameescape('Manpageview['.manpagetopic.'('.fnameescape(manpagebook).')]')
   let s:manpageview_curtopic= manpagetopic."(".manpagebook.")"
  endif

  " if there's a search pattern, use it {{{3
  if exists("manpagesrch")
   if search(manpagesrch,'w') != 0
    exe "norm! z\<cr>"
   endif
  endif

  " restore settings {{{3
  call s:MPVRestoreSettings()
"  call Dret("manpageview#ManPageView")
endfun

" ---------------------------------------------------------------------
" s:MPVSaveSettings: save and standardize certain user settings {{{2
fun! s:MPVSaveSettings()

  if !exists("s:sxqkeep")
"   call Dfunc("s:MPVSaveSettings()")
   let s:manwidth          = expand("$MANWIDTH")
   let s:sxqkeep           = &sxq
   let s:srrkeep           = &srr
   let s:repkeep           = &report
   let s:gdkeep            = &gd
   let s:cwhkeep           = &cwh
   let s:magickeep         = &l:magic
   setlocal srr=> report=10000 nogd magic
   if &cwh < 2
    " avoid hit-enter prompts
    setlocal cwh=2
   endif
  if has("win32") || has("win95") || has("win64") || has("win16")
   let &sxq= '"'
  else
   let &sxq= ""
  endif
  let s:curmanwidth = $MANWIDTH
  let $MANWIDTH     = winwidth(0)
"  call Dret("s:MPVSaveSettings")
 endif

endfun

" ---------------------------------------------------------------------
" s:MPV_RestoreSettings: {{{2
fun! s:MPVRestoreSettings()
  if exists("s:sxqkeep")
"   call Dfunc("s:MPV_RestoreSettings()")
   let &sxq      = s:sxqkeep     | unlet s:sxqkeep
   let &srr      = s:srrkeep     | unlet s:srrkeep
   let &report   = s:repkeep     | unlet s:repkeep
   let &gd       = s:gdkeep      | unlet s:gdkeep
   let &cwh      = s:cwhkeep     | unlet s:cwhkeep
   let &l:magic  = s:magickeep   | unlet s:magickeep
   let $MANWIDTH = s:curmanwidth | unlet s:curmanwidth
"   call Dret("s:MPV_RestoreSettings")
  endif
endfun

" ---------------------------------------------------------------------
" s:ManRestorePosn: restores file/position/screen-position {{{2
"                 (uses g:ManCurPosn)
fun! s:ManRestorePosn()
"  call Dfunc("s:ManRestorePosn()")

  if exists("g:ManCurPosn")
"   DechoWF "g:ManCurPosn<".g:ManCurPosn.">"
   if v:version >= 603
	exe 'keepjumps sil! source '.fnameescape(g:ManCurPosn)
   else
	exe 'sil! source '.fnameescape(g:ManCurPosn)
   endif
   unlet g:ManCurPosn
   sil! cunmap q
  endif

"  call Dret("s:ManRestorePosn")
endfun

" ---------------------------------------------------------------------
" s:ManSavePosn: saves current file, line, column, and screen position {{{2
fun! s:ManSavePosn()
"  call Dfunc("s:ManSavePosn()")

  let g:ManCurPosn= tempname()
  let keep_ssop   = &ssop
  let &ssop       = 'winpos,buffers,slash,globals,resize,blank,folds,help,options,winsize'
  if v:version >= 603
   exe 'keepjumps sil! mksession! '.fnameescape(g:ManCurPosn)
  else
   exe 'sil! mksession! '.fnameescape(g:ManCurPosn)
  endif
  let &ssop       = keep_ssop

"  call Dret("s:ManSavePosn")
endfun

" ---------------------------------------------------------------------
" s:ManPageInfo: {{{2
fun! s:ManPageInfo(type)
"  call Dfunc("s:ManPageInfo(type=".a:type.")")
  let s:before_K_posn= SaveWinPosn(0)

  if &ft != "info"
   " restore K and do a manpage lookup for word under cursor
"   DechoWF "ft!=info: restore K and do a manpage lookup of word under cursor"
   setlocal kp=manpageview#ManPageView
   if exists("s:manpageview_pfx_i")
    unlet s:manpageview_pfx_i
   endif
   call manpageview#ManPageView(1,0,expand("<cWORD>"))
"   call Dret("s:ManPageInfo : restored K")
   return
  endif

  if !exists("s:manpageview_pfx_i")
   let s:manpageview_pfx_i= g:manpageview_pfx_i
  endif

  " -----------
  " Follow Link
  " -----------
  if a:type == 0
   " extract link
   let curline  = getline(".")
"   DechoWF "type==0: curline<".curline.">"
   let ipat     = 1
   while ipat <= 4
    let link= matchstr(curline,s:linkpat{ipat})
"	DechoWF "..attempting s:linkpat".ipat.":<".s:linkpat{ipat}.">"
    if link != ""
     if ipat == 2
      let s:manpageview_pfx_i = substitute(link,s:linkpat{ipat},'\1','')
      let node                = "Top"
     else
      let node                = substitute(link,s:linkpat{ipat},'\1','')
 	 endif
"   	 DechoWF "ipat=".ipat."link<".link."> node<".node."> pfx<".s:manpageview_pfx_i.">"
 	 break
    endif
    let ipat= ipat + 1
   endwhile

  " ---------------
  " Go to next node
  " ---------------
  elseif a:type == 1
"   DechoWF "type==1: goto next node"
   let node= matchstr(getline(2),'Next: \zs[^,]\+\ze,')
   let fail= "no next node"

  " -------------------
  " Go to previous node
  " -------------------
  elseif a:type == 2
"   DechoWF "type==2: goto previous node"
   let node= matchstr(getline(2),'Prev: \zs[^,]\+\ze,')
   let fail= "no previous node"

  " ----------
  " Go up node
  " ----------
  elseif a:type == 3
"   DechoWF "type==3: go up one node"
   let node= matchstr(getline(2),'Up: \zs.\+$')
   let fail= "no up node"
   if node == "(dir)"
	echo "***sorry*** can't go up from this node"
"    call Dret("s:ManPageInfo : can't go up a node")
    return
   endif

  " --------------
  " Go to top node
  " --------------
  elseif a:type == 4
"   DechoWF "type==4: go to top node"
   let node= "Top"
  endif
"  DechoWF "node<".(exists("node")? node : '--n/a--').">"

  " use ManPageView() to view selected node
  if !exists("node")
   echohl ErrorMsg
   echo "***sorry*** unable to view selection"
   echohl None
  elseif node == ""
   echohl ErrorMsg
   echo "***sorry*** ".fail
   echohl None
  else
   call manpageview#ManPageView(1,0,node.".i")
  endif

"  call Dret("s:ManPageInfo")
endfun

" ---------------------------------------------------------------------
" ManPageInfoInit: {{{2
fun! ManPageInfoInit()
"  call Dfunc("ManPageInfoInit()")

  " some mappings to imitate the default info reader
  nmap    <buffer> 			<cr>	K
  noremap <buffer> <silent>	>		:call <SID>ManPageInfo(1)<cr>
  noremap <buffer> <silent>	n		:call <SID>ManPageInfo(1)<cr>
  noremap <buffer> <silent>	<		:call <SID>ManPageInfo(2)<cr>
  noremap <buffer> <silent>	p		:call <SID>ManPageInfo(2)<cr>
  noremap <buffer> <silent>	u		:call <SID>ManPageInfo(3)<cr>
  noremap <buffer> <silent>	t		:call <SID>ManPageInfo(4)<cr>
  noremap <buffer> <silent>	?		:he manpageview-info<cr>
  noremap <buffer> <silent>	d		:call manpageview#ManPageView(0,0,"dir.i")<cr>
  noremap <buffer> <silent>	<BS>	<C-B>
  noremap <buffer> <silent>	<Del>	<C-B>
  noremap <buffer> <silent>	<Tab>	:call <SID>NextInfoLink()<CR>
  noremap <buffer> <silent>	i		:call <SID>InfoIndexLink('i')<CR>
  noremap <buffer> <silent>	,		:call <SID>InfoIndexLink(',')<CR>
  noremap <buffer> <silent>	;		:call <SID>InfoIndexLink(';')<CR>

"  call Dret("ManPageInfoInit")
endfun

" ---------------------------------------------------------------------
" s:NextInfoLink: {{{2
fun! s:NextInfoLink()
    let ln = search('\%('.s:linkpat1.'\|'.s:linkpat2.'\|'.s:linkpat3.'\|'.s:linkpat4.'\)', 'w')
    if ln == 0
		echohl ErrorMsg
	   	echo '***sorry*** no links found' 
	   	echohl None
    endif
endfun

" ---------------------------------------------------------------------
" s:InfoIndexLink: supports info's "i" for index-search-for-topic {{{2
fun! s:InfoIndexLink(cmd)
"  call Dfunc("s:InfoIndexLink(cmd<".a:cmd.">)")
"  DechoWF "indx vars: line #".(exists("s:indxline")? s:indxline : '---')
"  DechoWF "indx vars: cnt  =".(exists("s:indxcnt")? s:indxcnt : '---')
"  DechoWF "indx vars: find =".(exists("s:indxfind")? s:indxfind : '---')
"  DechoWF "indx vars: link <".(exists("s:indxlink")? s:indxlink : '---').">"
"  DechoWF "indx vars: where<".(exists("s:wheretopic")? s:wheretopic : '---').">"
"  DechoWF "indx vars: srch <".(exists("s:indxsrchdir")? s:indxsrchdir : '---').">"

  " sanity checks
  if !exists("s:manpagetopic")
   echohl Error
   echo "(InfoIndexLink) no manpage topic available!"
   echohl NONE
"   call Dret("s:InfoIndexLink : no manpagetopic")
   return

  elseif !executable("info")
   echohl Error
   echo '(InfoIndexLink) the info command is not executable!'
   echohl NONE
"   call Dret("s:InfoIndexLink : info not exe")
   return
  endif

  if a:cmd == 'i'
   call inputsave()
   let s:infolink= input("Index entry: ","","shellcmd")
   call inputrestore()
   let s:indxfind= -1
  endif
"  DechoWF "infolink<".s:infolink.">"

  if s:infolink != ""

   if a:cmd == 'i'
	let mpt= substitute(s:manpagetopic,'\.i','','')
"	DechoWF 'system("info '.mpt.' --where")'
	let s:wheretopic    = substitute(system("info ".shellescape(mpt)." --where"),'\n','','g')
    let s:indxline      = 1
    let s:indxcnt       = 0
	let s:indxsrchdir   = 'cW'
"	DechoWF "new indx vars: cmd<i> where<".s:wheretopic.">"
"	DechoWF "new indx vars: cmd<i> line#".s:indxline
"	DechoWF "new indx vars: cmd<i> cnt =".s:indxcnt
"	DechoWF "new indx vars: cmd<i> srch<".s:indxsrchdir.">"
   elseif a:cmd == ','
	let s:indxsrchdir= 'W'
"	DechoWF "new indx vars: cmd<,> srch<".s:indxsrchdir.">"
   elseif a:cmd == ';'
	let s:indxsrchdir= 'bW'
"	DechoWF "new indx vars: cmd<;> srch<".s:indxsrchdir.">"
   endif

   let cmdmod= ""
   if v:version >= 603
    let cmdmod= "silent keepjumps "
   endif

   let wheretopic= s:wheretopic
   if s:indxcnt != 0
	let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info-'.s:indxcnt.".",'')
   else
	let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info.','')
   endif
"   DechoWF "initial wheretopic<".wheretopic."> indxcnt=".s:indxcnt

   " search for topic in various files loop
   while filereadable(wheretopic)
"	DechoWF "--- while loop: where<".wheretopic."> indxcnt=".s:indxcnt." indxline#".s:indxline

	" read file <topic.info-#.gz>
    setlocal ma
    sil! %d
	if s:indxcnt != 0
	 let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info-'.s:indxcnt.".",'')
	else
	 let wheretopic= substitute(wheretopic,'\.info\%(-\d\+\)\=\.','.info.','')
	endif
"    DechoWF "    exe ".cmdmod."r ".fnameescape(wheretopic)
    try
	 exe cmdmod."r ".fnameescape(wheretopic)
	catch /^Vim\%((\a\+)\)\=:E484/
	 break
	finally
	 if search('^File:','W') != 0
	  silent 1,/^File:/-1d
	  1put! =''
	 else
	  1d
	 endif
	endtry
	setlocal noma nomod

	if s:indxline < 0
	 if a:cmd == ','
	  " searching forwards
	  let s:indxline= 1
"	  DechoWF "    searching forwards from indxline#".s:indxline
	 elseif a:cmd == ';'
	  " searching backwards
	  let s:indxline= line("$")
"	  DechoWF "    searching backwards from indxline#".s:indxline
	 endif
	endif

	if s:indxline != 0
"     DechoWF "    indxline=".s:indxline." infolink<".s:infolink."> srchflags<".s:indxsrchdir.">"
	 exe fnameescape(s:indxline)
     let s:indxline= search('^\n\zs'.s:infolink.'\>\|^[0-9.]\+.*\zs\<'.s:infolink.'\>',s:indxsrchdir)
"     DechoWF "    search(".s:infolink.",".s:indxsrchdir.") yields: s:indxline#".s:indxline
     if s:indxline != 0
	  let s:indxfind= s:indxcnt
	  echo ",=Next Match  ;=Previous Match"
"      call Dret("s:InfoIndexLink : success!  (indxfind=".s:indxfind.")")
      return
     endif
	endif

	if a:cmd == 'i' || a:cmd == ','
	 let s:indxcnt  = s:indxcnt + 1
	 let s:indxline = 1
	elseif a:cmd == ';'
	 let s:indxcnt  = s:indxcnt - 1
	 if s:indxcnt < 0
	  let s:indxcnt= 0
"	  DechoWF "    new indx vars: cmd<".a:cmd."> indxcnt=".s:indxcnt
	  break
	 endif
	 let s:indxline = -1
	endif
"	DechoWF "    new indx vars: cmd<".a:cmd."> indxcnt =".s:indxcnt
"	DechoWF "    new indx vars: cmd<".a:cmd."> indxline#".s:indxline
   endwhile
  endif
"  DechoWF "end-while indx vars: find=".s:indxfind." cnt=".s:indxcnt

  " clear screen
  setlocal ma
  sil! %d
  setlocal noma nomod

  if s:indxfind < 0
   " unsuccessful :(
   echohl WarningMsg
   echo "(InfoIndexLink) unable to find info for topic<".s:manpagetopic."> indx<".s:infolink.">"
   echohl NONE
"   call Dret("s:InfoIndexLink : unable to find info for ".s:manpagetopic.":".s:infolink)
   return
  elseif a:cmd == ','
   " no more matches
   let s:indxcnt = s:indxcnt - 1
   let s:indxline= 1
   echohl WarningMsg
   echo "(InfoIndexLink) no more matches"
   echohl NONE
"   call Dret("s:InfoIndexLink : no more matches")
   return
  elseif a:cmd == ';'
   " no more matches
   let s:indxcnt = s:indxfind
   let s:indxline= -1
   echohl WarningMsg
   echo "(InfoIndexLink) no previous matches"
   echohl NONE
"   call Dret("s:InfoIndexLink : no previous matches")
   return
  endif
endfun

" ---------------------------------------------------------------------
" manpageview#ManPageTex: {{{2
fun! manpageview#ManPageTex()
  let s:before_K_posn = SaveWinPosn(0)
  let topic           = '\'.expand("<cWORD>")
"  call Dfunc("manpageview#ManPageTex() topic<".topic.">")
  call manpageview#ManPageView(1,0,topic)
"  call Dret("manpageview#ManPageTex")
endfun

" ---------------------------------------------------------------------
" manpageview#ManPageTexLookup: {{{2
fun! manpageview#ManPageTexLookup(book,topic)
"  call Dfunc("manpageview#ManPageTexLookup(book<".a:book."> topic<".a:topic.">)")
"  call Dret("manpageview#ManPageTexLookup ".lookup)
endfun

" ---------------------------------------------------------------------
" manpageview#:ManPagePhp: {{{2
fun! manpageview#ManPagePhp()
  let s:before_K_posn = SaveWinPosn(0)
  let topic           = substitute(expand("<cWORD>"),'()\=.*$','.php','')
"  call Dfunc("manpageview#ManPagePhp() topic<".topic.">")
  call manpageview#ManPageView(1,0,topic)
"  call Dret("manpageview#ManPagePhp")
endfun

" ---------------------------------------------------------------------
" manpageview#:ManPagePython: {{{2
fun! manpageview#ManPagePython()
  let s:before_K_posn = SaveWinPosn(0)
  let topic           = substitute(expand("<cWORD>"),'()\=.*$','.py','')
"  call Dfunc("manpageview#ManPagePython() topic<".topic.">")
  call manpageview#ManPageView(1,0,topic)
"  call Dret("manpageview#ManPagePython")
endfun

" ---------------------------------------------------------------------
" manpageview#KMan: set default extension for K map {{{2
fun! manpageview#KMan(ext)
"  call Dfunc("manpageview#KMan(ext<".a:ext.">)")

  let s:before_K_posn = SaveWinPosn(0)
  if a:ext == "perl"
   let ext= "pl"
  elseif a:ext == "gvim"
   let ext= "vim"
  elseif a:ext == "info" || a:ext == "i"
   let ext    = "i"
   set ft=info
  elseif a:ext == "man"
   let ext= ""
  else
   let ext= a:ext
  endif
"  DechoWF "ext<".ext.">"

  " change the K map
"  DechoWF "change the K map"
  sil! nummap K
  sil! nunmap <buffer> K
  if exists("g:manpageview_K_{ext}") && g:manpageview_K_{ext} != ""
   exe "nmap <silent> <buffer> K :call ".g:manpageview_K_{ext}."\<cr>"
"   DechoWF "nmap <silent> K :call ".g:manpageview_K_{ext}
  else
"   DechoWF "change K map (KMan)"
   nmap <unique> K <Plug>ManPageView
"   DechoWF "nmap <unique> K <Plug>ManPageView"
  endif

"  call Dret("manpageview#KMan ")
endfun

let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
" Modeline: {{{1
" vim: ts=4 fdm=marker
