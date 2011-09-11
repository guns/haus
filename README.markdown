
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

 - Allow tasks to operate on specific files
 - haus rm file (unlinks / deletes file)
 - haus restore
 - haus ssh ls
 - haus ssh add
 - haus ssh rm
 - haus ssh clean
 - All Queue instance methods should be thread safe
   - Implement locking for add_*
 - Shouldn't touch `File.umask`; just `lchmod` and `install`
 - Finish `Haus::Clean` tests
 - Better `--help` documentation
   - Accept `haus help COMMAND` invocation
 - `HAUS_PATH` environment variable
 - Perhaps more of the tests should be using `Tempfile`


### LICENSE ###

    Copyright (c) 2011 Sung Pae <self@sungpae.com>
    Distributed under the MIT license.
    http://www.opensource.org/licenses/mit-license.php
