### BASH PROMPTS ###

EXPORT_PROMPTS() {
    if [[ $SSH_TTY ]]; then
        local delim='■' color
        if ((EUID)); then
            color="${PS_COLOR:-36}"
        else
            color="${PS_COLOR:-31}"
        fi
    elif [[ "$USER" == test ]]; then
        local delim='§'
        color="${PS_COLOR:-36}"
    else
        local delim='§' color
        if ((EUID)); then
            color="${PS_COLOR:-37}"
        else
            color="${PS_COLOR:-35}"
        fi
    fi

    export PS1="\e[0;${color}m\\H \e[1m${delim}\e[22m \\w\\n\e[0;${color}m\\u\\$\e[0m "
    export PS2="\e[0;${color}m${USER//?/░}░\e[0m "
}

# Show exit status of last command if non-zero
PROMPT_COMMAND='__exitstatus__'
__exitstatus__() {
    local s=$?
    (($s)) && echo -ne "\033[3;31m($s)\033[0m "
}

EXPORT_PROMPTS
unset EXPORT_PROMPTS
