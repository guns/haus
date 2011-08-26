
     _______ _______ _______ _______
    |   |   |   _   |   |   |     __|
    |       |       |   |   |__     |
    |___|___|___|___|_______|_______|

        * -=-=-=-=-=-=-=-=-=-=- *


_Don't leave home, take it with you._


### WORK IN PROGRESS ###

Dotfile and ssh key management system.


### REQUIREMENTS ###

 - POSIX-compatible Operating System
   (compatibility layers like Cygwin are unsupported)
 - Ruby 1.8.6+


### TODO ###

 - haus restore
 - haus ssh ls
 - haus ssh add
 - haus ssh rm
 - haus ssh clean
 - Shouldn't touch `File.umask`; just `lchmod` and `install`
 - Finish `Haus::Clean` tests
 - Better `--help` documentation
 - `HAUS_PATH` environment variable
 - Accept `haus help COMMAND` invocation
 - All logged files should be colorized according to `LS_?COLORS`
 - Perhaps more of the tests should be using `Tempfile`


### LICENSE ###

    Copyright (c) 2011 Sung Pae <self@sungpae.com>
    Distributed under the MIT license.
    http://www.opensource.org/licenses/mit-license.php
