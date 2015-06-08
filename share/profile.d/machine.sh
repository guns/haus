### CONTAINER ENVIRONMENT HACKS

# Use host's X server
export DISPLAY=':0'

# We will never connect from a basic terminal emulator
if [[ "$TERM" == vt220 ]]; then
    export TERM='rxvt-unicode-256color'
fi

# Use different prompt colors
export PS_DELIM='◩'
if ((EUID == 0)); then
    export PS_COLOR='38;5;227'
else
    export PS_COLOR='38;5;243'
fi

# No /dev/shm host bind
export QT_X11_NO_MITSHM='1'
