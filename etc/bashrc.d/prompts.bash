### BASH PROMPTS ###

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
    export PS4='━ '
}

# Show exit status of last command if non-zero
PROMPT_COMMAND='__exitstatus__'
__exitstatus__() {
    local s=$?
    ((s)) && echo -ne "\033[3;31m($s)\033[0m "
}

# Arguments are bash parameter expansions: '/\\u/\\u is a luser'
__PS1TOGGLE__() {
    # Seed PS1 stack variable if unset
    declare -p __PS1STACK__ &>/dev/null || __PS1STACK__=("$PS1")

    # Check for existing transformation
    local idx count=${#__PS1STACK__[@]} exists
    for ((idx = 1; idx < count; ++idx)); do
        if [[ "$*" == "${__PS1STACK__[idx]}" ]]; then
            exists=1
            break
        fi
    done

    # Remove existing pattern, or push new one
    if ((exists)); then
        __PS1STACK__=("${__PS1STACK__[@]:0:idx}" "${__PS1STACK__[@]:idx+1}")
    else
        __PS1STACK__+=("$*")
    fi

    # Replay transformations
    local expr
    PS1="${__PS1STACK__[0]}"
    for expr in "${__PS1STACK__[@]:1}"; do
        eval "PS1=\"\${PS1$expr}\""
    done
}

EXPORT_PROMPTS
unset EXPORT_PROMPTS
