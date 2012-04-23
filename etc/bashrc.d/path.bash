### SHELL PATH ###

# Requires ~/.bashrc.d/functions.bash

PATH_ARY=(
    ~/bin                               # User programs
    /usr/local/{,s}bin                  # Local administrator's programs
    "$RUBYPATH"                         # Used for switching top Ruby
    /opt/ruby/{1.9,1.8,1.8.6}/bin       # Ruby installations
    ~/.cabal/bin                        # Haskell programs
    {~/.haus,/opt/haus/bin}             # Haus programs
    "$PATH"                             # Existing PATH
    /{,usr/}{,s}bin                     # Canonical Unix PATH
    /{opt,usr}/X11/bin                  # X11 programs
    /opt/brew/{,s}bin                   # Homebrew (OS X)
    /opt/passenger/bin                  # Phusion Passenger
    /usr/{local/,}games                 # Games
)

EXPORT_PATH
