### HAPPY HACKING ###

GREETINGS() {
    local date="$(date +%H:%M:%S\ %Z)" color
    local hour="${date%%:*}"; hour="${hour#0}"

    if   ((hour < 6 || hour > 21)); then color='34' # night
    elif ((hour < 10));             then color='36' # morning
    elif ((hour < 18));             then color='33' # day
    else                                 color='35' # evening
    fi

    echo -e "\n\e[1;32mGNU Bash \e[0;3m($BASH_VERSION)\e[0m ⚡ \e[1;${color}m$date\e[0m\n"

    if ((EUID)) && type fortune &>/dev/null; then
        local flag='-a'
        ((NOOFFENSE)) && flag=''
        fortune $flag && echo
    fi
}

GREETINGS
unset GREETINGS
