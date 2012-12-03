###
### BASH PROMPTS
###

EXPORT_PROMPTS() {
    # Environment overrides
    local delim="$PS_DELIM" color="$PS_COLOR"

    if [[ "$SSH_TTY" ]]; then
        delim="${delim:-■}" # Tunnel
        if ((EUID)); then
            color="${color:-36}"
        else
            color="${color:-31}"
        fi
    else
        delim="${delim:-§}" # Section
        if ((EUID)); then
            color="${color:-37}"
        else
            color="${color:-35}"
        fi
    fi

    if [[ "$USER" == test ]]; then
        color="${PS_COLOR:-36}"
    fi

    # Interactive prompts need to surround escapes with RL_PROMPT_*_IGNORE,
    # which have special escapes in Bash: \[ \]
    export PS1="\[\e[0;${color}m\]\\H \[\e[1m\]${delim}\[\e[22m\] \\w\\n\[\e[0;${color}m\]\\u\\$\[\e[0m\] "
    export PS2="\[\e[0;${color}m\]${USER//?/░}░\[\e[0m\] "
    export PS4='• '
}

# Show exit status of last command if non-zero
PROMPT_COMMAND='__EXITSTATUS__'
__EXITSTATUS__() {
    local s=$?
    ((s)) && echo -ne "\033[3;31m($s)\033[0m "
}

EXPORT_PROMPTS
unset EXPORT_PROMPTS
