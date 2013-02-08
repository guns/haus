if !exists('g:refheap_token')
  let g:refheap_token = ''
endif

if !exists('g:refheap_username')
  let g:refheap_username = ''
endif

if !exists('g:refheap_api_url')
  let g:refheap_api_url = 'https://www.refheap.com/api/'
endif

" I didn't come up with this, but it seems to work for getting the currently
" selected region.
function! GetVisualSelection()
  try
    let a_save = @a
    silent! normal! gv"ay
    return @a
  finally
    let @a = a_save
  endtry
endfunction

" This is easily the most insane I've ever written on purpose.
function! refheap#Refheap(count, line1, line2, ...)
  let lastarg = a:0 == 1 ? ",'" . a:1 . "'" : ''
  execute 'python refheap(' . a:count . ',' . a:line1 . ',' . a:line2 . lastarg . ')'
endfunction

python << EOF

import vim
import json
import urllib
import urllib2
import xerox

REFHEAP_URL = vim.eval('g:refheap_api_url')

def buffer_contents():
    return '\n'.join(vim.current.buffer)

def selected():
    return vim.eval('GetVisualSelection()')

def refheap_req(text, priv):
    ext = vim.eval('expand("%:e")')
    if ext:
        ext = '.' + ext
    data = {'language': ext,
            'contents': text,
            'private': priv}
    username = vim.eval('g:refheap_username')
    token = vim.eval('g:refheap_token')
    if username and token:
        data['username'] = username
        data['token'] = token
    req = urllib2.Request(REFHEAP_URL + "paste", urllib.urlencode(data))
    try:
        res = json.loads(urllib2.urlopen(req).read())['url']
        xerox.copy(res)
        print "Copied " + res + " to your clipboard."
    except urllib2.HTTPError, e:
        print e.read()

def refheap(count, line1 = None, line2 = None, priv = None):
    if priv == "-p":
        priv = "true"
    else:
        priv = "false"
    if count < 1:
        refheap_req(buffer_contents(), priv)
    else:
        refheap_req(selected(), priv)

EOF
