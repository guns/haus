if !exists('g:refheap_token')
  let g:refheap_token = ''
endif

if !exists('g:refheap_username')
  let g:refheap_username = ''
endif

if !exists('g:refheap_api_url')
  let g:refheap_api_url = 'https://refheap.com/api/'
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
  execute 'ruby refheap(' . a:count . ',' . a:line1 . ',' . a:line2 . lastarg . ')'
endfunction

ruby << EOF

require 'rubygems'
require 'rubyheap'
require 'copier'

user  = VIM::evaluate("g:refheap_username")
token = VIM::evaluate("g:refheap_token")

if not user.empty? && token.empty?
  $heap = Refheap::Paste.new(user, token)
else
  $heap = Refheap::Paste.new()
end

def buffer_contents()
  buffer = VIM::Buffer.current
  1.upto(buffer.count).map { |i| buffer[i] }.join("\n")
end

def refheap(count, line1 = nil, line2 = nil, priv = nil)
  if priv == "-p"
    priv = "true"
  else
    priv = "false"
  end
  if count < 1
    text = buffer_contents()
  else
    text = VIM::evaluate("GetVisualSelection()")
  end
  ref = $heap.create(text,
                     :language => "." + VIM::evaluate('expand("%:e")'),
                     :private => priv)['url']
  Copier(ref)
  puts "Copied #{ref} to the clipboard."
end

EOF
