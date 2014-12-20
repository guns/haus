###
### Environment variables
###
### Requires ~/.bashrc.d/functions.bash
###

# Bash history
export HISTSIZE='65535'
export HISTIGNORE='&:cd:.+(.):ls:lc: *' # Ignore dups, common commands, and leading spaces

# Editor
export EDITOR='vim'
export VISUAL='vim'

# Locales
export LANG='en_US.UTF-8'
export LC_COLLATE='C'                   # Traditional ASCII sorting

# BSD and GNU colors
export CLICOLOR='1'
export LSCOLORS='ExFxCxDxbxegedabagacad'
export LS_COLORS='di=01;34:ln=01;35:so=01;32:pi=01;33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:ow=30;42:tw=30;43'

# Readline
export RLWRAP_HOME="$HOME/.rlwrap"

# Pager
LESS_ARY=(
    --force                             # Force open non-regular files
    --clear-screen                      # Print buffer from top of screen
    --dumb                              # Do not complain about terminfo errors
    --ignore-case                       # Like vim ignorecase + smartcase
    --no-lessopen                       # Ignore LESSOPEN preprocessor
    --long-prompt                       # Show position percentage
    --RAW-CONTROL-CHARS                 # Only interpret SGR escape sequences
    --chop-long-lines                   # Disable soft wrapping
    --no-init                           # Prevent use of alternate screen
    --tilde                             # Do not show nonextant lines as `~`
    --shift 8                           # Horizontal movement in columns
); GC_VARS LESS_ARY
export LESS="${LESS_ARY[@]}"
export LESSSECURE='1'                   # More secure
export LESSHISTFILE='-'                 # No ~/.lesshst
export LESS_TERMCAP_md=$'\033[37m'      # Begin bold
export LESS_TERMCAP_so=$'\033[36m'      # Begin standout-mode
export LESS_TERMCAP_us=$'\033[4;35m'    # Begin underline
export LESS_TERMCAP_mb=$'\033[5m'       # Begin blink
export LESS_TERMCAP_se=$'\033[0m'       # End standout-mode
export LESS_TERMCAP_ue=$'\033[0m'       # End underline
export LESS_TERMCAP_me=$'\033[0m'       # End mode
export PAGER='less'                     # Should be a single word to avoid quoting problems

# Ruby
export RUBYLIB="$HOME/.local/lib/ruby"
export BUNDLE_PATH="$HOME/.bundle"
if [[ "$SSH_TTY" ]]; then
    export RAILS_ENV='production'  RACK_ENV='production'
else
    export RAILS_ENV='development' RACK_ENV='development'
fi

# Go
export GOPATH="$HOME/.local/pkg/go"

# OS X
if __OS_X__; then
    # Prefer not copying Apple doubles and extended attributes
    export COPYFILE_DISABLE=1
    export COPY_EXTENDED_ATTRIBUTES_DISABLE=1
fi
