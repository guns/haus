### CONTAINER ENVIRONMENT HACKS

if ((EUID == 0)) && [[ "$TERM" == vt220 ]]; then
    while read -r -d $'\0' kv; do
        if [[ "${kv:0:5}" == "TERM=" ]]; then
            export "$kv"
            break
        fi
    done < /proc/1/environ
fi

if ((EUID == 0)); then
    export PS_COLOR=33
else
    export PS_COLOR='38;5;244'
fi

export PS_DELIM='◩'
export DISPLAY=':0'
export QT_X11_NO_MITSHM='1'
