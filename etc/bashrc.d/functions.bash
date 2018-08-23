###
### BASH INITIALIZATION FUNCTIONS
###

# Helper functions for defining a bash environment. All functions and
# variables in this file can be unset by calling `CLEANUP`.
# Bash 3.1+ compatible.

# __GC_FUNC__ contains functions to be unset after shell init.
# __GC_VARS__ contains variables to be unset after shell init.
__GC_FUNC__=(GC_FUNC GC_VARS)
__GC_VARS__=(__GC_FUNC__ __GC_VARS__)

# Corresponding accumulation convenience functions.
# Param: $@ List of file/function/variable names
GC_FUNC() { __GC_FUNC__+=("$@"); }
GC_VARS() { __GC_VARS__+=("$@"); }

# Unset temporary functions and variables
CLEANUP() {
    unset -f "${__GC_FUNC__[@]}"
    unset "${__GC_VARS__[@]}"
}; GC_FUNC CLEANUP

### Abort shell initialization
# Param: $* Error message
ABORT() {
    # Explain
    (($#)) && printf "%s\n\n" "$*" >&2

    # Stack trace
    local i n=$((${#BASH_SOURCE[@]} - 1))
    for ((i = 0; i < n; ++i)); do
        echo "-> ${BASH_SOURCE[i+1]}:${BASH_LINENO[i]}:${FUNCNAME[i]}" >&2
    done

    # Clean up, send interrupt signal, and suspend execution
    CLEANUP
    printf "\n\e[1;3;31mAborting shell initialization.\e[0m\n\n" >&2
    while true; do kill -INT $$; sleep 60; done
}; GC_FUNC ABORT

### Source file and abort on failure
# Param: $1 Filename
REQUIRE() {
    [[ -r "$1" ]] || ABORT "Unable to source \"$1\""
    source "$1"   || ABORT "\`source $1\` returned false!"
}; GC_FUNC REQUIRE

### Simple wrapper around `type`
# Param: $@ List of commands/aliases/functions
HAVE() { type "$@" &>/dev/null; }; GC_FUNC HAVE

### Lazy completion transfer function:
#
# The Bash-completion project v2.0 introduces dynamic loading of completions,
# which greatly shortens shell initialization time. A consequence of this is
# that completions can no longer be simply transferred using:
#
#   eval "$({ complete -p $source || echo :; } 2>/dev/null)" $target
#
# A workaround is to create a completion function that dynamically loads the
# source completion, then replaces itself with the new completion, finally
# invoking the new completion function to save the user from having to resend
# the completion command.
#
# This is also much faster at shell initialization.
#
# Param: $1 Source command
# Param: $2 Target command
TCOMP() {
    local src="$1" alias="$2"

    eval "__TCOMP_${alias}__() {
        # Unset self and remove existing compspec
        unset \"__TCOMP_${alias}__\" 2>/dev/null
        complete -r \"$alias\"

        # Load completion through bash-completion 2.0 dynamic loading function
        if complete -p \"$src\" &>/dev/null || __load_completion \"$src\"; then
            while true; do
                local cspec=\"\$(complete -p \"$src\" 2>/dev/null)\"
                local cfunc=\"\$(sed -ne \"s/.*-F \\\\([^[:space:]]*\\\\) .*/\\\\1/p\" <<< \"\$cspec\")\"
                if [[ \"\$cfunc\" == __TCOMP_*__ ]]; then
                    # If this is another lazy completion, call now to load
                    \"\$cfunc\"
                else
                    break
                fi
            done

            # Dynamic load may have loaded empty compspec
            [[ \"\$cspec\" ]] || return 1

            # Transfer compspec target
            \$cspec \"$alias\"

            # Invoke compspec to complete current request
            if [[ \"\$cfunc\" ]]; then
                # compgen -F does not work!
                _xfunc \"$src\" \"\$cfunc\" \"\$@\"
            elif [[ \"\$cspec\" == 'complete '* ]]; then
                COMPREPLY=(\$(compgen \$(sed -ne \"s/^complete \\\\(.*\\\\) ${src}.*/\\\\1/p\" <<< \"\$cspec\") \\
                                      \"\${COMP_WORDS[COMP_CWORD]}\"))
            fi
        fi
    }; complete -F \"__TCOMP_${alias}__\" \"$alias\""
}; GC_FUNC TCOMP

### `cd` wrapper creation:
#
# CD_FUNC cdfoo /usr/local/foo ...
#
#   * Creates shell variable $cdfoo, suitable for use as an argument:
#
#       $ cp bar $cdfoo/subdir
#
#   * Creates shell function cdfoo():
#
#       $ cdfoo             # Changes working directory to `/usr/local/foo`
#       $ cdfoo bar/baz     # Changes working directory to `/usr/local/foo/bar/baz`
#
#   * Creates completion function __cdfoo__() which completes cdfoo():
#
#       $ cdfoo <Tab>       # Returns all directories in `/usr/local/foo`
#       $ cdfoo bar/<Tab>   # Returns all directories in `/usr/local/foo/bar`
#
#   * If `/usr/local/foo` does not exist or is not a directory, and multiple
#     arguments are given, each argument is tested until an extant directory
#     is found. Otherwise does nothing and returns false.
#
# CD_FUNC -e cdgems 'ruby -rubygems -e "puts Gem.dir"'
#
#   * Shell variable $cdgems only created after first invocation
#
#   * Lazy evaluation; avoids costly invocations at shell init
#
# CD_FUNC -n ... ../..
#
#   * No check for extant directory with `-n`
#
# Option: -e     Parameter $2 is a shell expression
# Option: -n     Do not check if directory exists
# Option: -x     Export shell variable
# Param:  $1     Name of created function/variable
# Param:  ${@:2} List of directories, or a shell expression with `-e`
CD_FUNC() {
    local isexpr=0 checkdir=1 doexport=''
    local OPTIND OPTARG opt
    while getopts :enx opt; do
        case $opt in
        e) isexpr=1;;
        n) checkdir=0;;
        x) doexport='export';;
        esac
    done
    shift $((OPTIND-1))

    local name expr dir

    if ((isexpr)); then
        name="$1" expr="$2"

        eval "$name() {
            if [[ \"\$$name\" ]]; then
                cd \"\$$name/\$1\"
            else
                cd \"\$($expr)/\$1\"
                # Set shell variable on first call
                $doexport $name=\"\$PWD\" 2>/dev/null
            fi
        }"
    else
        local name="$1"

        # Loop through arguments till we find a match
        if ((checkdir)); then
            local arg
            for arg in "${@:2}"; do
                if [[ -d "$arg" ]]; then
                    dir="$arg"
                    break
                fi
            done
            [[ "$dir" ]] || return 1
        else
            dir="$2"
        fi

        # Set shell variable and function
        eval "$doexport $name=\"$dir\"" 2>/dev/null
        eval "$name() { cd \"$dir/\$1\"; }"
    fi

    # Set completion function
    eval "__${name}__() {
        local cur=\"\${COMP_WORDS[COMP_CWORD]}\" file
        local IFS=\$'\x1F'
        COMPREPLY=(\$(
            # Change to base directory
            \"$name\"
            # Ignore case and dequote current word when globbing
            shopt -s nocaseglob
            for file in \"\$(eval printf %s \"\$cur\")\"*; do
                if [[ -d \"\$file\" ]]; then
                    printf '%s/\x1F' \$(sed -e 's/\\([^[:alnum:]%+,.\\/@^_-]\\)/\\\\\\1/g' <<< \"\$file\")
                fi
            done
        ))
    }"

    # Complete the shell function
    complete -o nospace -F "__${name}__" "$name"
}; GC_FUNC CD_FUNC

### Init script wrapper creation:
#
# RC_FUNC rcd /etc/rc.d ...
#
#   * Creates shell function rcd(), which executes scripts in `/etc/rc.d`:
#
#       $ rcd sshd restart
#
#   * Creates completion function __rcd__() which completes rcd():
#
#       $ rcd <Tab>                     # Returns all scripts in /etc/rc.d
#       $ rcd sshd <Tab>                # Returns subcommands for /etc/rc.d/sshd
#
#   * If `/etc/rc.d` does not exist or is not a directory, and multiple
#     arguments are given, each argument is tested until an extant directory
#     is found. Otherwise does nothing and returns false.
#
# Param: $1     Name of created function
# Param: ${@:2} List of rc/init directories
RC_FUNC() {
    local name="$1" arg dir
    for arg in "${@:2}"; do
        if [[ -d "$arg" ]]; then
            dir="$arg"
            break
        fi
    done

    [[ "$dir" ]] || return 1

    # Shell function
    eval "$name() { [[ -x \"$dir/\$1\" ]] && \"$dir/\$1\" \"\${@:2}\"; }"

    # Completion function
    eval "__${name}__() {
        local cur=\"\${COMP_WORDS[COMP_CWORD]}\"
        local prev=\"\${COMP_WORDS[COMP_CWORD-1]}\"
        local words

        if [[ \"\$prev\" == \"\${COMP_WORDS[0]}\" ]]; then
            pushd . &>/dev/null
            cd \"$dir\"
            COMPREPLY=(\"\$cur\"*)
            popd &>/dev/null
        else
            COMPREPLY=(\$(compgen -W 'start stop restart' -- \"\$cur\"))
        fi
    }"

    # Complete the shell function
    complete -F __${name}__ $name
}; GC_FUNC RC_FUNC

### HAPPY HACKING

GREETINGS() {
    local date="$(date +%H:%M:%S\ %Z)"
    local hour="${date%%:*}"
    local color

    hour="${hour#0}"

    if   ((hour < 6 || hour > 21)); then color='34' # night
    elif ((hour < 10));             then color='36' # morning
    elif ((hour < 18));             then color='33' # day
    else                                 color='35' # evening
    fi

    printf "\n\e[1;32mGNU Bash \e[0;3m($BASH_VERSION)\e[0m ✶ \e[1;${color}m$date\e[0m\n\n" >&2
}; GC_FUNC GREETINGS
