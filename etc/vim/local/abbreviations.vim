""" Lowercase Abbreviations for Commonly Used Commands

let cmds = '
    \ A AD AS AT AV G Gblame Gbrowse Gcd Gcommit Gdiff Ge Gedit Ggrep Git Glcd
    \ Glog Gmove Gpedit Gread Gremove Gsdiff Gsplit Gstatus Gtabedit Gvdiff
    \ Gvsplit Gw Gwq Gwrite R RD RDlib RDspec RDtask RDtest RS RSlib RSspec RStask
    \ RStest RT RTlib RTspec RTtask RTtest RV RVlib RVspec RVtask RVtest Rake Rcd
    \ Rlcd Rlib Rspec Rtags Rtask Rtest Ack AckAdd AckFile AckFromSearch Align
    \ AlignCtrl AlignPop AlignPush AlignReplaceQuotedSpaces AnsiEsc B Bufonly
    \ Capture CaptureMaps ColorHEX ColorRGB CommandT CommandTBuffer CommandTFlush
    \ Ctags DM DelimitMateReload DelimitMateSwitch DelimitMateTest DiffOrig
    \ DoMatchParen EXtermColorTable Explore GLVS GPGEditOptions GPGEditRecipients
    \ GPGViewOptions GPGViewRecipients GetLatestVimScripts GetScripts Gitv
    \ GundoRenderGraph GundoToggle HEMan HMan Helptags Hexplore Hitest Interleave
    \ KMan LAck LAckAdd Man Mapall MatchDebug MkVimball NERDTree NERDTreeClose
    \ NERDTreeFind NERDTreeFromBookmark NERDTreeMirror NERDTreeToggle NR NRM
    \ NRMulti NRP NRPrepare NRV NUD NW NarrowRegion NarrowWindow NetUserPass
    \ NetrwClean NetrwSettings Nexplore NoMatchParen Nread Nsource Nwrite
    \ OMan OXtermColorTable Open Org Pexplore PreserveMap Preview PreviewHtml
    \ PreviewMarkdown PreviewRdoc PreviewRonn PreviewRst PreviewTextile Qfdo RM
    \ RMan RWP Rails RegbufOpen Remapall RepoRoot Rexplore RmVimball RubyFold
    \ SM SWP SXtermColorTable Say Scratch Screen ScreenShell ScreenShellAttach
    \ ScreenShellVertical SetAutowrap SetMatchParen SetTextwidth SetWhitespace
    \ Sexplore SpeedDatingFormat Sscratch SynStack TOhtml TXtermColorTable
    \ TagbarClose TagbarOpen TagbarOpenAutoClose TagbarSetFoldlevel TagbarShowTag
    \ TagbarToggle Texplore TextobjRubyblockDefaultKeyMappings Todo UltiSnipsEdit
    \ UseVimball VEMan VMan VXtermColorTable Vexplore VimballList Vimuntar
    \ XtermColorTable
\ '

for cmd in split(cmds)
    execute 'cnoreabbrev ' . tolower(cmd) . ' ' . cmd
endfor
