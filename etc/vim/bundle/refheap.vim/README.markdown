# refheap.vim

This is a tiny little Vim plugin for pasting to
[RefHeap](https://refheap.com).

# Installation

The majority of this plugin is written in Python. Because of this,
you'll need to have a copy of Vim that is compiled with +python enabled.
This plugin also makes use of a Python library for copying text to the
system clipboard in a cross platform way called xerox, so you'll need
that as well. You can install it like so:

```
pip install xerox
```

If you don't have pip:

```
easy_install xerox
```

*If you're on Linux, version 0.3.0 of xerox doesn't work due to a small syntax
error in the Linux part of the library. I've only tested this with
0.3.1.*

If you're on Windows, you'll need to install the pywin32 library as well
(in the same way you installed xerox).

On Linux, xerox uses xclip, so you'll need to install that if your
distro doesn't already have it. On OS X, you'll need pbcopy installed,
but it should be installed by default. On Windows, you shouldn't need
anything but the pywin32 library.

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
