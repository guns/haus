###
### Environment variables
###

# Bash history
export HISTFILE="$HOME/.cache/bash_history"
export HISTSIZE='65535'
export HISTIGNORE='&:cd:.+(.):ls: *'    # Ignore dups, common commands, and lines with leading spaces
#export HISTTIMEFORMAT='%Y-%m-%d %T │ ' # History timestamps

# Editor
export EDITOR='vim'
export VISUAL='vim'

# Locales
export LANG='en_US.UTF-8'
export LC_COLLATE='C'                   # Traditional ASCII sorting

# BSD and GNU colors
export CLICOLOR='1'
export LSCOLORS='ExFxCxDxbxegedabagacad'
export LS_COLORS='di=1;38;5;27:ln=1;35:or=1;31:mh=1;3:so=1;32:pi=1;33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:ow=30;42:tw=30;43'

# Readline
export RLWRAP_HOME="$HOME/.rlwrap"

# Pager
LESSOPTS=(
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
)
export LESS="${LESSOPTS[@]}"
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
export SYSTEMD_LESS="${LESSOPTS[@]}"
unset LESSOPTS

# Ruby
[[ -n "$RUBYLIB" ]] || export RUBYLIB="$HOME/.local/lib/ruby"

# Python
[[ -n "$PYTHONPATH" ]] || export PYTHONPATH="$HOME/.local/lib/python"

# Go
[[ -n "$GOPATH" ]] || export GOPATH='/opt/src/go'

# For xdg-open
# https://wiki.archlinux.org/index.php/Environment_Variables#Examples
export DE='xfce'

# Qt
export QT_QPA_PLATFORMTHEME='qt5ct'

# Java
export _JAVA_AWT_WM_NONREPARENTING='1'

# GnuPG
if [[ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne "$$" ]]; then
    export SSH_AUTH_SOCK="/run/user/${SUDO_UID:-$EUID}/gnupg/S.gpg-agent.ssh"
fi
