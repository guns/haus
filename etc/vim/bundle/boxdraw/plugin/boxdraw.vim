" Box drawing module for Vim 6.0
" (C) Andrew Nikitin, 2002
" 2002-01-07 -- created by nsg
" 2002-01-08 -- first box drawing (single only)
" 2002-01-09 -- (00:42) fixed col(".") bug (note vim bug k"tylj does not retu)
" 2002-01-09 -- optimize
" 2002-01-10 -- double boxes
" 2002-01-16 -- use script-local var and access function instead of global
" 2002-01-30 -- ,a mapping (box->ascii conversion)
" 2003-11-10 -- implemented MB avoiding "number Ctl-V"
" 2004-06-18 -- fixed ToAscii so it replaces "─"; trace path (g+arrow)
" 2004-06-23 -- merged single-byte and utf-8 support in one file
" 2004-06-30 -- do not use shift+arrows unless in win32
" 2008-12-17 -- special processing for line-block movements, changed cabbr for
" perl


let s:o_utf8='--0251--001459--50585a----------0202----0c1c----525e------------51--51--53--5f--54--60------------------------------------------00185c--003468------------------1024----2c3c--------------------56--62--65--6b--------------------------------------------------505b5d----------506769----------5561------------646a------------57--63----------66--6c------------------------------------------------------------------01'
let s:i_utf8='44cc11------------------14------50------05------41------15--------------51--------------54--------------45--------------55--------------------------------------88221824289060a009060a81428219262a9162a29864a889468a9966aa14504105------40010410'
let s:o_cp437='--b3ba--c4c0d3--cdd4c8----------b3b3----dac3----d5c6------------ba--ba--d6--c7--c9--cc------------------------------------------c4d9bd--c4c1d0------------------bfb4----c2c5--------------------b7--b6--d2--d7--------------------------------------------------cdbebc----------cdcfca----------b8b5------------d1d8------------bb--b9----------cb--ce'
let s:i_cp437='----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------115191626090a222a08242815005455415445519260a288aa82a88aa894698640609182466994114'

let s:scriptfile=expand("<sfile>:h") 

let s:running = 0

"
" Activate mode. Assigned to ,b macro.
"
fu! <SID>S()
  let s:running = 1
  if has("gui_running")
    " se enc=utf8
  en
  let s:ve=&ve
  setl ve=all
  " Note that typical terminal emulator program (Putty, in particular) does
  " not support Shift arrows too good. You will, probably, have to redefines
  " those to, say, 
  " ,<Up> etc.
  if has("win32")
    :
  else
    nnoremap <buffer> K  :call <SID>M(1,'k')<CR>
    nnoremap <buffer> J  :call <SID>M(16,'j')<CR>
    nnoremap <buffer> H  :call <SID>M(64,'h')<CR>
    nnoremap <buffer> L  :call <SID>M(4,'l')<CR>
    nnoremap <buffer> gK :call <SID>G(0)<CR>
    nnoremap <buffer> gL :call <SID>G(1)<CR>
    nnoremap <buffer> gJ :call <SID>G(2)<CR>
    nnoremap <buffer> gH :call <SID>G(3)<CR>
    vnoremap <buffer> K  <esc>:call <SID>MB('k')<CR>
    vnoremap <buffer> J  <esc>:call <SID>MB('j')<CR>
    vnoremap <buffer> H  <esc>:call <SID>MB('h')<CR>
    vnoremap <buffer> L  <esc>:call <SID>MB('l')<CR>
  en
  " vm <buffer> <Leader>a :ToAscii<cr>
  " nm <buffer> <Leader>b :call <SID>E()<CR>
  " nm <buffer> <Leader>s :call <SID>SetLT(1)<CR>
  " nm <buffer> <Leader>d :call <SID>SetLT(2)<CR>
  exec "cabbr <buffer> perl perl ".s:scriptfile

  let s:bdlt=1
endf

fu! s:SetLT(thickness)
  let s:bdlt=a:thickness
endf

" Deactivate mode.
" Unmap macros, restore &ve option
fu! <SID>E()
  let s:running = 0
  if has("win32")
    :
  else
    silent! nun <buffer> K
    silent! nun <buffer> J
    silent! nun <buffer> H
    silent! nun <buffer> L
    silent! nun <buffer> gK
    silent! nun <buffer> gL
    silent! nun <buffer> gJ
    silent! nun <buffer> gH
    silent! vun <buffer> K
    silent! vun <buffer> J
    silent! vun <buffer> H
    silent! vun <buffer> L
  en
  " silent! nun <buffer> <Leader>a
  " silent! nun <buffer> <Leader>b
  " silent! nun <buffer> <Leader>s
  " silent! nun <buffer> <Leader>d
  silent! cuna <buffer> perl
  let &ve=s:ve
  unlet s:ve
  echo "Finished Boxdrawing mode"
endf

fu! s:GetBoxCode(char)
  " check if symbol from unicode boxdrawing range
  " E2=1110(0010)
  " 25=  10(0101)xx
  if 'utf-8'== &enc
    if(0xE2==char2nr(a:char[0])&&0x25==char2nr(a:char[1])/4)
      retu '0x'.strpart(s:i_utf8,2*(char2nr(a:char[1])%4*64+char2nr(a:char[2])%64),2)
    en
  else " Assume cp437 encoding
    retu '0x'.strpart(s:i_cp437,2*char2nr(a:char),2)
  en
  retu 0
endf

" Try neihgbour in direction 'd' if c is true. Mask m for the direction
" should also be supplied.
" Function returns neighboring bit
" Unicode entries are encoded in utf8 as
"   7 bit : 0vvvvvvv
"  11 bit : 110vvvvv 10vvvvvv
"  16 bit : 1110vvvv 10vvvvvv 10vvvvvv
fu! s:T(c,d,m)
  if(a:c)
    exe 'norm mt'.a:d.'"tyl`t'
    let c=s:GetBoxCode(@t)
    retu c%a:m*4/a:m 
  en
  retu 0
endf

" 3*4^x, where x=0,1,2,3
" fu! s:Mask(x)
"   retu ((6+a:x*(45+a:x*(-54+a:x*27)))/2)
" endf

" Move cursor (follow) in specified direction
" Return new direction if new position is valid, -1 otherwise
" dir: 'kljh'
"       ^>V<
"       0123
" mask: 3 12 48 192      
" let @x=3|echo (6+@x*(45+@x*(-54+@x*27)))/2
"
fu! <SID>F(d)
  exe 'norm '.('kljh'[a:d]).'"tyl'
  let c=s:GetBoxCode(@t)
  let i=0
  let r=-1
  while i<4
    if 0!=c%4 && a:d!=(i+2)%4
      if r<0
        let r=i
      else
        retu -1
      endif
    endif
    let c=c/4
    let i=i+1
  endw
  retu r
endf

fu! <SID>G(d)
  let y=line(".")
  let x=virtcol(".")
  let n=a:d
  while n>=0
    let n=s:F(n) 
    if y==line(".") && x==virtcol(".") 
      echo "Returned to same spot"
      break
    endif
  endw
endf

" Move cursor in specified direction (d= h,j,k or l). Mask s for
" the direction should also be supplied
"
fu! <SID>M(s,d)
  let t=@t
  let x=s:T(1<col("."),'h',16)*64+s:T(line(".")<line("$"),'j',4)*16+s:T(1,'l',256)*4+s:T(1<line("."),'k',64)
  let @t=t
  let c=a:s*s:bdlt+x-x%(a:s*4)/a:s*a:s
  "echo 'need c='.c.' x='.x
  if 'utf-8'==&enc
    let o=strpart(s:o_utf8,2*c,2)
    if o!='--' && o!='' 
      exe "norm r\<C-V>u25".o.a:d
    en
  else
    let o=strpart(s:o_cp437,2*c,2)
    if o!='--' && o!='' 
      exe "norm r\<C-V>x".o.a:d
    en
  en
  echo "Boxdrawing mode" 
endf

scriptencoding utf8
command! -range ToAscii :silent <line1>,<line2>s/┌\|┬\|┐\|╓\|╥\|╖\|╒\|╤\|╕\|╔\|╦\|╗\|├\|┼\|┤\|╟\|╫\|╢\|╞\|╪\|╡\|╠\|╬\|╣\|└\|┴\|┘\|╙\|╨\|╜\|╘\|╧\|╛\|╚\|╩\|╝/+/ge|:silent <line1>,<line2>s/[│║]/\|/ge|:silent <line1>,<line2>s/[═─]/-/ge

command! -range ToHorz :<line1>,<line2>s/─\|═/-/g
command! -range ToHorz2 :<line1>,<line2>s/─/-/g
" 0000000: 636f 6d6d 616e 6421 202d 7261 6e67 6520  command! -range 
" 0000010: 546f 486f 727a 203a 3c6c 696e 6531 3e2c  ToHorz :<line1>,
" 0000020: 3c6c 696e 6532 3e73 2fe2 9480 5c7c e295  <line2>s/...\|..
" 0000030: 9029 2f6f 2f67 0d0a                      .)/o/g..
command! -range ToVert :<line1>,<line2>s/│\|║/\|/g

" Move block dispatch
fu! s:MB(d)
  if visualmode()=='' || visualmode()=='v'
    call s:MRB(a:d)
  elseif visualmode()=='V'
    call s:MLB(a:d)
  en
endf

" Move line block
fu! s:MLB(d)
  if a:d=='j' || a:d=='k'
    let l:cmd= "norm gv\"yd".a:d."\"yP1V"
    exe l:cmd
  elseif a:d=='h'
    normal gv
    :'<,'>s/^.//
    normal gv
  elseif a:d=='l'
    normal gv
    :'<,'>s/^/ /
    normal gv
  en
endf

" Move Rectangular block
" sideeffect: stores contents of a block in "y 
" 1<C-V> does not work good in 6.0 when multibyte characters are involved
" gvp does not work good ...
" gv also has some problems
" See http://vim.sourceforge.net/tips/tip.php?tip_id=808 for different way to
" paste
fu! s:MRB(d)
  " It seems that rectangular boxes and multibyte do not live together too
  " good asof version 6.3
  " Normally something like
  " exe 'norm gv"yygvr '.a:d.'1<C-V>"ypgv'
  " should have worked
  let l:y1=line(".")
  let l:x1=virtcol(".")
  "echo l:x1."-".l:y1
  normal gv"yygvo
  let l:y2=line(".")
  let l:x2=virtcol(".")
  if l:x1>l:x2 | let l:t=l:x1 | let l:x1=l:x2 | let l:x2=l:t | endif
  if l:y1>l:y2 | let l:t=l:y1 | let l:y1=l:y2 | let l:y2=l:t | endif
  let l:pos=l:y1."G0"
  if 1<l:x1 | let l:pos=l:pos.(l:x1-1)."l" | endif
  let l:size=""
  if 0<l:y2-l:y1 | let l:size=l:size.(l:y2-l:y1)."j" | endif
  if 0<l:x2-l:x1 | let l:size=l:size.(l:x2-l:x1)."l" | endif
  exe "normal gvr ".l:pos.a:d."".l:size."d\"yPgvjk"
endf

command! -bar Boxdraw if s:running | call <SID>E() | else | call <SID>S() | endif
command! -bar -nargs=1 BoxdrawThickness call <SID>SetLT(<f-args>)
