###
### SHELL PATH
###

# Requires ~/.bashrc.d/functions.bash

PATH_ARY=(
    ~/bin                               # User programs
    /usr/local/{,s}bin                  # Local administrator's programs
    "$RUBYPATH"                         # Used for switching top Ruby
    /opt/ruby/{2.0,1.9,1.8,1.8.6}/bin   # Ruby installations
    ~/.cabal/bin                        # Haskell programs
    {~/.haus/bin,/opt/haus/bin}         # Haus programs
    "$PATH"                             # Existing PATH
    /opt/brew/{,s}bin                   # Homebrew (OS X)
)

EXPORT_PATH
