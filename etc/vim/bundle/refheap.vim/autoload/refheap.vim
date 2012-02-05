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

$languages = {"clj"          => "Clojure",
              "cljs"         => "Clojure",
              "fy"           => "Fancy",
              "groovy"       => "Groovy",
              "factor"       => "Factor",
              "io"           => "Io",
              "ioke"         => "Ioke",
              "lua"          => "Lua",
              "pl"           => "Perl",
              "perl"         => "Perl",
              "py"           => "Python",
              "rb"           => "Ruby",
              "mirah"        => "Duby",
              "tcl"          => "Tcl",
              "ada"          => "Ada",
              "c"            => "C",
              "cpp"          => "C++",
              "d"            => "D",
              "dylan"        => "Dylan",
              "flx"          => "Felix",
              "fortran"      => "Fortran",
              "nim"          => "Nimrod",
              "go"           => "Go",
              "java"         => "Java",
              "def"          => "Modula-2",
              "mod"          => "Module-2",
              "ooc"          => "ooc",
              "m"            => "Objective-C",
              "pro"          => "Prolog",
              "prolog"       => "Prolog",
              "scala"        => "Scala",
              "vala"         => "Vala",
              "boo"          => "Boo",
              "cs"           => "C#",
              "fs"           => "F#",
              "n"            => "Nemerle",
              "vb"           => "VB.NET",
              "lisp"         => "Common Lisp",
              "erl"          => "Erlang",
              "hs"           => "Haskell",
              "lhs"          => "Literate Haskell",
              "ml"           => "OCaml",
              "scm"          => "Scheme",
              "rkt"          => "Scheme",
              "ss"           => "Scheme",
              "v"            => "Verilog",
              "r"            => "R",
              "abap"         => "ABAP",
              "applescript"  => "AppleScript",
              "ahk"          => "Autohotkey",
              "awk"          => "Awk",
              "sh"           => "Bash",
              "bat"          => "Batch",
              "bf"           => "Brainfuck",
              "befunge"      => "Befunge",
              "ns2"          => "NewSpeak",
              "ps"           => "PostScript",
              "proto"        => "Protobuf",
              "r3"           => "REBOL",
              "st"           => "Smalltalk",
              "cmake"        => "CMake",
              "dpatch"       => "Darcs Patch",
              "diff"         => "Diff",
              "init"         => "INI",
              "properties"   => "Java Properties",
              "rst"          => "rST",
              "tex"          => "LaTeX",
              "vim"          => "VimL",
              "yaml"         => "YAML",
              "coffeescript" => "CoffeeScript",
              "css"          => "CSS",
              "html"         => "HTML",
              "xml"          => "XML",
              "haml"         => "HAML",
              "js"           => "Javascript",
              "php"          => "PHP",
              "sass"         => "SASS",
              "txt"          => "Plain Text",
              "scaml"        => "Scaml"}

$languages.default("Plain Text")

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
                     :language => $languages[VIM::evaluate('expand("%:e")')],
                     :private => priv)['url']
  Copier(ref)
  puts "Copied #{ref} to the clipboard."
end

EOF
