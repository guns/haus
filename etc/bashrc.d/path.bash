###
### SHELL PATH
###
### Requires ~/.bashrc.d/functions.bash
###

PATH_ARY=(
    ~/{.local/,}bin                     # User programs
    /usr/local/{,s}bin                  # Local admin programs
    {~/.haus/bin,/opt/haus/bin}         # Haus programs
    "$PATH"                             # Existing PATH
)

EXPORT_PATH
