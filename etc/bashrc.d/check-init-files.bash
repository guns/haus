### SHELL INITIALIZATION FILES PERMISSIONS TEST ###

SECLIST+=(
    /etc/profile                        # System shell init
    /etc/bash.bashrc                    # System interactive bash init
    /etc/bash.bash.logout               # System bash logout file
    /etc/inputrc                        # System readline settings
    ~/.bash_profile                     # Bash login init file: 1st
    ~/.bash_login                       # Bash login init file: 2nd
    ~/.profile                          # Shell login init file: 3rd
    ~/.bashrc                           # Bash interactive init file
    ~/.bash_logout                      # Bash logout file
    ~/.inputrc                          # User readline settings
    "$INPUTRC"                          # ENV readline override
    "$BASH_ENV"                         # Bash init override
    "$ENV"                              # POSIX Bash init override
); CHECK_SECLIST
