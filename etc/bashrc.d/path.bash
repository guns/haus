###
### SHELL PATH
###

# Requires ~/.bashrc.d/functions.bash

PATH_ARY=(
    ~/{.local/,}bin                     # User programs
    /usr/local/{,s}bin                  # Local admin programs
    "$RUBYPATH"                         # Used for switching top Ruby
    /opt/ruby/{2.0,1.9,1.8,1.8.6}/bin   # Ruby installations
    {~/.haus/bin,/opt/haus/bin}         # Haus programs
    "$PATH"                             # Existing PATH
    /opt/brew/{,s}bin                   # Homebrew (OS X)
)

EXPORT_PATH
