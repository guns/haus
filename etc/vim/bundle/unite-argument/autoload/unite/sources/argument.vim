"=============================================================================
" FILE: argument.vim
" AUTHOR:  Yann Thomas-Gérard <inside@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim
let s:source = {
            \ 'name' : 'argument',
            \ 'description' : 'candidates from the vim argument list',
            \ 'hooks' : {},
            \ 'default_kind' : 'buffer',
            \}

function! unite#sources#argument#define() "{{{
    return s:source
endfunction
"}}}

function! s:source.hooks.on_init(args, context) "{{{
    let a:context.source__candidates = []

    for i in argv()
        call add(a:context.source__candidates, {
                    \ 'word': bufname(i),
                    \ 'action__buffer_nr': bufnr(i),
                    \ })
    endfor
endfunction
"}}}

function! s:source.gather_candidates(args, context) "{{{
    return a:context.source__candidates
endfunction
"}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
    return ['no-current']
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
