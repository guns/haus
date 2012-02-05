if !has('ruby')
  finish
endif

if exists('loaded_refheap')
  finish
endif

let loaded_refheap = 1

" Define our commands.
command! -range -nargs=? Refheap call refheap#Refheap(<count>, <line1>, <line2>, <f-args>)

