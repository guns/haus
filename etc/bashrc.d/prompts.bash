###
### BASH PROMPTS
###

if [[ "$SSH_TTY" ]]; then
    PS_DELIM="${PS_DELIM:-■}" # SSH tunnel
    if ((EUID > 0)); then
        PS_COLOR="${PS_COLOR:-36}"
    else
        PS_COLOR="${PS_COLOR:-31}"
    fi
else
    PS_DELIM="${PS_DELIM:-§}" # Section
    if ((EUID > 0)); then
        PS_COLOR="${PS_COLOR:-37}"
    else
        PS_COLOR="${PS_COLOR:-35}"
    fi
fi

# Interactive prompts need to surround escapes with RL_PROMPT_*_IGNORE,
# which have special escapes in Bash: \[ \]
export PS1="\[\e[0;${PS_COLOR}m\]\\H \[\e[1m\]${PS_DELIM}\[\e[22m\] \\w\\n\[\e[0;${PS_COLOR}m\]\\u\\$\[\e[0m\] "
export PS2="\[\e[0;${PS_COLOR}m\]${USER//?/░}░\[\e[0m\] "
export PS4='• '
unset PS_DELIM PS_COLOR

# Show exit status of last command if non-zero
__EXITSTATUS__() {
    local s=$?
    ((s)) && printf "\033[3;31m($s)\033[0m "
}
PROMPT_COMMAND='__EXITSTATUS__'
