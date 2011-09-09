""" Lowercase Abbreviations for Commonly Used Commands

" exe 'Capture command' | exe 'norm ggdj' | %s/\v^.{4}// | %s/\v^(\S+).*/\1/ | %s/\v^.{1,2}$// | exe 'norm ggVGJgqip' | %s/\v(.*)/    \\ \1/
let cmds = '
    \ Gblame Gbrowse Gcd Gcommit Gdiff Gedit Ggrep Git Glcd Glog Gmove Gpedit
    \ Gread Gremove Gsdiff Gsplit Gstatus Gtabedit Gvdiff Gvsplit Gwq Gwrite
    \ RDlib RDspec RDtask RDtest RSlib RSspec RStask RStest RTlib RTspec
    \ RTtask RTtest RVlib RVspec RVtask RVtest Rake Rcd Rlcd Rlib Rspec Rtags
    \ Rtask Rtest Ack AckAdd AckFile AckFromSearch Align AlignCtrl AlignPop
    \ AlignPush AlignReplaceQuotedSpaces AnsiEsc Bufonly Capture CaptureMaps
    \ CapturePane ColorHEX ColorRGB CommandT CommandTBuffer CommandTFlush Ctags
    \ DelimitMateReload DelimitMateSwitch DelimitMateTest DiffOrig DoMatchParen
    \ EXtermColorTable Explore GLVS GPGEditOptions GPGEditRecipients GPGViewOptions
    \ GPGViewRecipients GetLatestVimScripts GetScripts Gitv GundoRenderGraph
    \ GundoToggle HEMan HMan Helptags Hexplore Hitest Interleave KMan LAck
    \ LAckAdd Man MapReadlineUnicodeBindings Mapall MatchDebug MkVimball
    \ NERDTree NERDTreeClose NERDTreeFind NERDTreeFromBookmark NERDTreeMirror
    \ NERDTreeToggle NRM NRMulti NRP NRPrepare NRV NUD NarrowRegion NarrowWindow
    \ NetUserPass NetrwClean NetrwSettings Nexplore NoMatchParen Nread Nsource
    \ Nwrite OMan OXtermColorTable Open Org Pexplore PreserveMap Preview
    \ PreviewHtml PreviewMarkdown PreviewRdoc PreviewRonn PreviewRst PreviewTextile
    \ Qfdo RMan RWP Rails RegbufOpen Remapall RepoRoot RmVimball RubyFold
    \ RunCurrentFile RunCurrentMiniTestCase SWP SXtermColorTable Say Scratch Screen
    \ ScreenShell ScreenShellAttach ScreenShellVertical SetAutowrap SetMatchParen
    \ SetTextwidth SetWhitespace Sexplore SpeedDatingFormat Sscratch SynStack TOhtml
    \ TXtermColorTable TagbarClose TagbarOpen TagbarOpenAutoClose TagbarSetFoldlevel
    \ TagbarShowTag TagbarToggle Texplore TextobjRubyblockDefaultKeyMappings Todo
    \ UltiSnipsEdit UseVimball VEMan VMan VXtermColorTable Vexplore VimballList
    \ Vimuntar XtermColorTable
\ '

for cmd in split(cmds)
    execute 'cnoreabbrev ' . tolower(cmd) . ' ' . cmd
endfor
