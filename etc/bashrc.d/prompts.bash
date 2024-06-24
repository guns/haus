###
### BASH PROMPTS
###

if [[ "$SSH_CONNECTION" ]]; then
    __PS_DELIM__="${PS_DELIM:-■}" # SSH tunnel
else
    __PS_DELIM__="${PS_DELIM:-§}" # Section
fi

if ((EUID == 0)); then
    __PS_COLOR__="${PS_COLOR:-35}"
else
    __PS_COLOR__="${PS_COLOR:-37}"
fi

# Interactive prompts need to surround escapes with RL_PROMPT_*_IGNORE,
# which have special escapes in Bash: \[ \]
export PS1="\[\e[0;${__PS_COLOR__}m\]\\H \[\e[1m\]${__PS_DELIM__}\[\e[22m\] \\w\\n\[\e[0;${__PS_COLOR__}m\]\\u\\$\[\e[0m\] "
export PS2="\[\e[0;${__PS_COLOR__}m\]${USER//?/░}░\[\e[0m\] "
export PS4='• '
unset __PS_DELIM__ __PS_COLOR__

# Show exit status of last command if non-zero
__EXITSTATUS__() {
    local s=$?
    ((s)) && printf "\001\033[3;31m($s)\033[0m\002 "
}
PROMPT_COMMAND='__EXITSTATUS__'
