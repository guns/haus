### BASH INITIALIZATION FUNCTIONS ###

# Helper functions for defining a bash environment.
# All functions and variables can be unset by calling `CLEANUP`.

# SECLIST contains files that should be checked for loose privileges.
# GC_FUNC contains functions to be unset after shell init.
# GC_VARS contains variables to be unset after shell init.
SECLIST=()
GC_FUNC=(SECLIST GC_FUNC GC_VARS)
GC_VARS=(SECLIST GC_FUNC GC_VARS)

# Corresponding accumulation functions for convenience
SECLIST() { SECLIST+=("$@"); }
GC_FUNC() { GC_FUNC+=("$@"); }
GC_VARS() { GC_VARS+=("$@"); }

# Sweep garbage collection lists
CLEANUP() {
    unset -f "${GC_FUNC[@]}"
    unset "${GC_VARS[@]}"
}; GC_FUNC CLEANUP


# Abort the login process with an optional message
ABORT() {
    # Explain
    (($#)) && echo -e >&2 "$*\n"

    # Stack trace
    local i
    for ((i = 0; i < ${#BASH_SOURCE[@]} - 1; ++i)); do
        echo >&2 "-> ${BASH_SOURCE[i+1]}:${BASH_LINENO[i]}:${FUNCNAME[i]}"
    done

    # Clean up, send interrupt signal, and suspend execution
    CLEANUP
    echo -e >&2 "\n\e[1;3;31mAborting shell initialization.\e[0m\n"
    kill -INT $$
    while true; do sleep 60; done
}; GC_FUNC ABORT


# Source file and abort on failure
REQUIRE() {
    [[ -e "$1" ]] || ABORT "\"$1\" does not exist!"
    [[ -r "$1" ]] || ABORT "No permissions to read \"$1\""
    source "$1"   || ABORT "\`source $1\` returned false!"
}; GC_FUNC REQUIRE

# Simple wrapper around `type`
HAVE() { type "$@" &>/dev/null; }; GC_FUNC HAVE
# Simple platform checks
__OSX__()   { [[ "$MACHTYPE" == *darwin* ]]; }; GC_FUNC __OSX__
__LINUX__() { [[ "$MACHTYPE" == *linux* ]]; }; GC_FUNC __LINUX__


# Check to see if current user or root owns and has sole write privileges on
# all files in SECLIST.
#
# Clears SECLIST on success and aborts on failure.
CHECK_SECLIST() {
    # Don't spin up a ruby interpreter if we don't have to
    (( ${#SECLIST[@]} )) || return

    if ruby -e '
        ARGV.each do |file|
            next if file.empty?
            path = File.expand_path file
            next unless File.exists? path
            stat = File.stat path

            if stat.uid != Process.euid and not stat.uid.zero?
                require "etc"
                fmt = "%s is trusted, but is owned by %s!"
                abort fmt % [path.inspect, Etc.getpwuid(stat.uid).name.inspect]
            elsif not ((mode = stat.mode) & 0002).zero?
                abort "%s is trusted, but is world writable!" % path.inspect
            elsif not (mode & 0020).zero?
                abort "%s is trusted, but is group writable!" % path.inspect
            end
        end
    ' "${SECLIST[@]}"; then
        SECLIST=()
    else
        ABORT "\nYour shell is at risk of being compromised."
    fi
}; GC_FUNC CHECK_SECLIST


# Processes array variable PATH_ARY and exports PATH.
#
# PATH_ARY may consist of directories or colon-delimited PATH strings.
# Duplicate, non-searchable, and non-extant directories are pruned, as well
# directories that are not owned by the current user or root.
EXPORT_PATH() {
    export PATH="$(ruby -e '
        print ARGV.map { |e| e.split ":" }.flatten.uniq.select do |path|
            if File.directory? path and File.executable? path
                stat = File.stat path
                stat.uid == Process.euid or stat.uid.zero?
            end
        end.join(":")
    ' "${PATH_ARY[@]}")"

    # We want to sweep this variable
    GC_VARS PATH_ARY

    # We also want to check permissions before proceeding
    local IFS=$':'
    SECLIST+=($PATH)
    unset IFS
    CHECK_SECLIST
}; GC_FUNC EXPORT_PATH


# Smarter aliasing function:
#
#   * Transfers any existing completions for a command to the alias:
#
#       complete -p exec                        => `complete -c exec`
#       ALIAS x='exec' && complete -p x         => `complete -c x`
#       complete -p sudo                        => `complete -c sudo`
#       ALIAS -n s='sudo' && complete -p s      => (no completions)
#
#   * Skips alias and returns false if command does not exist:
#
#       ALIAS pony='/bin/magic-pony'            => (no alias)
#       ALIAS unicorn='magic-pony --with-horn'  => (no alias)
#       echo $!                                 => `1`
#
#   * Lazy evaluation:
#
#       ALIAS mp='magic-pony' ls='ls -Ahl'      => `ls` remains unaliased
#
# NOTE: In order to attain acceptable performance, this function is not
#       parameter compatible with the `alias` builtin! All arguments MUST be
#       in the form `name=value`
#
ALIAS() {
    local arg
    for arg in "$@"; do
        # Split argument into name and (array)value; eval preserves user's
        # quoting and escaping
        local name="${arg%%=*}"
        eval "local val=(${arg#*=})"
        local cmd="${val[0]}" opts="${val[@]:1}"

        if HAVE "$cmd"; then
            # Escape spaces in cmd; doesn't escape other shell metacharacters!
            builtin alias "$name=${cmd// /\\ } ${opts[@]}"
            # Transfer completions to the new alias
            if [[ "$name" != "$cmd" ]]; then
                eval $({ complete -p "$cmd" || echo :; } 2>/dev/null) "$name"
            fi
        else
            return 1
        fi
    done
}; GC_FUNC ALIAS


# `cd` wrapper creation:
#
# CD_FUNC foo /usr/local/foo ...
#
#   * Creates shell variable $foo, suitable for use as an argument:
#
#       $ cp bar $foo/subdir
#
#   * Creates shell function foo():
#
#       $ foo               # Changes working directory to `/usr/local/foo`
#       $ foo bar/baz       # Changes working directory to `/usr/local/foo/bar/baz`
#
#   * Creates completion function __foo__() which completes foo():
#
#       $ foo <Tab>         # Returns all directories in `/usr/local/foo`
#       $ foo bar/<Tab>     # Returns all directories in `/usr/local/foo/bar`
#
#   * If `/usr/local/foo` does not exist or is not a directory, and multiple
#     arguments are given, each argument is tested until an extant directory
#     is found. Otherwise does nothing and returns false.
#
# CD_FUNC -n ... ../..
#
#   * No check for extant directory with `-n`
#
# CD_FUNC -f cdgems 'ruby -rubygems -e "puts Gem.dir"'
#
#   * Shell variable $cdgems only created after first invocation
#
#   * Lazy evaluation; avoids costly invocations at shell init
#
CD_FUNC() {
    local OPTIND OPTARG opt isfunc checkdir=1
    while getopts :fn opt; do
        case $opt in
        f) isfunc=1;;
        n) checkdir=0;;
        esac
    done
    shift $((OPTIND-1))

    local name func dir

    if ((isfunc)); then
        name="$1" func="$2"

        eval "$name() {
            if [[ \"\$$name\" ]]; then
                cd \"\$$name/\$1\"
            else
                cd \"\$($func)/\$1\"
                # Set shell variable on first call
                [[ \"\$$name\" ]] || $name=\"\$PWD\" 2>/dev/null
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
        eval "$name=\"$dir\"" 2>/dev/null
        eval "$name() { cd \"$dir/\$1\"; }"
    fi

    # Set completion function
    eval "__${name}__() {
        local cur=\"\${COMP_WORDS[COMP_CWORD]}\"
        local words=\"\$(
            # Change to base directory
            $name

            local base line
            # If the current word doesn't have a slash, this is the first comp
            if [[ \"\$cur\" != */* ]]; then
                command ls -A1 | while read line; do
                    [[ -d \"\$line\" ]] && echo \"\${line%/}/\"
                done
            else
                # Chomp the trailing slash
                base=\"\${cur%/}\"

                # If this directory doesn't exist, try its parent
                [[ -d \"\$base\" ]] || base=\"\${base%/*}\"

                # Return directories
                command ls -A1 \"\$base\" | while read line; do
                    [[ -d \"\$base/\$line\" ]] && echo \"\$base/\${line%/}/\"
                done
            fi
        )\"

        local IFS=\$'\\n'
        COMPREPLY=(\$(compgen -W \"\$words\" -- \"\$cur\"))
    }"

    # Complete the shell function
    complete -o nospace -o filenames -F "__${name}__" "$name"
}; GC_FUNC CD_FUNC


# Init script wrapper creation:
#
# INIT_FUNC rcd /etc/rc.d ...
#
#   * Creates shell function rcd():
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
INIT_FUNC() {
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
            words=\"\$(command ls -1 \"$dir/\")\"
        else
            words='start stop restart'
        fi

        COMPREPLY=(\$(compgen -W \"\$words\" -- \$cur))
    }"

    # Complete the shell function
    complete -F __${name}__ $name
}; GC_FUNC INIT_FUNC
