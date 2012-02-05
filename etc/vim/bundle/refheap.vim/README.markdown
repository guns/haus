# refheap.vim

This is a tiny little Vim plugin for pasting to
[RefHeap](https://refheap.com).

# Installation

The majority of this plugin is written mostly in Ruby. Because of this,
you need to have a Vim compiled with +ruby enabled.

Your Vim should be compiled against Ruby 1.8 (I've tested with 1.8.7).
Ruby 1.9.2 is somewhat broken in Vim and probably wont work. On Linux,
you should automatically be fine. MacVim users installing MacVim from
homebrew should do so with the system Ruby enabled. If you use rvm, make
sure you run `rvm use system` before `brew install macvim`.

There are a few gems you need to use this plugin.


You'll want to copy `plugin/` and `autoload/` to `~/.vim`. If you're
using pathogen, you'll just want to put this whole directory into your
pathogen path and it'll do the rest.

# Usage

This library defines a single command, `:Refheap`. If you run this
command with no visual selection, it will paste the whole file. If you
run the command with a visual selection, it'll only paste that specific
region. By default, pastes are public. If you want to make them private,
pass the `-p` option to `:Refheap`.

By default, your pastes will be anonymous. If you want to associate them
with an account, add the following to your `.vimrc`:

```
let g:refheap_token = 'yourtokenhere'
let g:refheap_user = 'username'
```

You can get your API token by logging in and navigating to the [RefHeap
API](https://refheap.com/api) page. Your username is in the upper right
corner next to the 'logout' button.
