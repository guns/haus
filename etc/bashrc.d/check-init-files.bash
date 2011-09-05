### SHELL INITIALIZATION FILES PERMISSIONS TEST ###

# Requires ~/.bashrc.d/functions.bash

__SECLIST__+=(
    /etc/profile                        # System POSIX init
    /etc/bash.bashrc                    # System interactive bash init
    /etc/bash.bash.logout               # System bash logout
    /etc/inputrc                        # System readline
    ~/.bash_profile                     # Bash login init (1)
    ~/.bash_login                       # Bash login init (2)
    ~/.profile                          # POSIX login init (3)
    ~/.bashrc                           # Bash interactive init
    ~/.bash_logout                      # Bash logout
    ~/.inputrc                          # User readline
    "$INPUTRC"                          # Readline override
    "$BASH_ENV"                         # Bash init override
    "$ENV"                              # POSIX init override
)

CHECK_SECLIST
