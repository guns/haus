### CONTAINER ENVIRONMENT HACKS

if ((EUID == 0)); then
    export PS_COLOR=33
else
    export PS_COLOR='38;5;244'
fi

export PS_DELIM='◩'
export QT_X11_NO_MITSHM='1'
