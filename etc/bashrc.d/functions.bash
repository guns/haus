### BASH INITIALIZATION FUNCTIONS ###

# All variables and functions from this script can be unset by calling
# `__CLEANUP__`

# SECLIST contains files that should be checked for loose privileges.
# GC_FUNC contains functions to be unset after shell init.
# GC_VARS contains variables to be unset after shell init.
SECLIST=() GC_FUNC=(SECLIST GC_FUNC GC_VARS) GC_VARS=(SECLIST GC_FUNC GC_VARS)

# Corresponding accumulator functions for convenience
SECLIST() { SECLIST+=("$@"); }
GC_FUNC() { GC_FUNC+=("$@"); }
GC_VARS() { GC_VARS+=("$@"); }

# Sweep garbage collection lists
__CLEANUP__() {
    unset -f "${GC_FUNC[@]}"
    unset "${GC_VARS[@]}"
}; GC_FUNC LOGIN_CLEANUP


# Returns 1 if sourcing fails
require() {
    [[ -r "$1" ]] || return 1
    . "$1" || return 1
}; GC_FUNC require


# Check to see if current user or root owns and has sole write privileges on
# all files in SECLIST.
#
# Clears SECLIST on exit.
CHECK_SECLIST() {
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
                abort "%s is trusted, but it is world writable!" % path.inspect
            elsif not (mode & 0020).zero?
                abort "%s is trusted, but it is group writable!" % path.inspect
            end
        end
    ' "${SECLIST[@]}"; then
        SECLIST=()
    else
        return 1
    fi
}; GC_FUNC CHECK_SECLIST


# Processes array variable PATH_ARY and exports PATH.
# Prunes duplicate and non-extant entries.
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

    # We also want to check permissions now
    local IFS=$':'; SECLIST+=($PATH); unset IFS
    CHECK_SECLIST || return 1
}; GC_FUNC EXPORT_PATH


# Expanded aliasing function:
#
# Adds `-e` option to alias, which has these effects:
#
#   * Replaces programs with their absolute paths:
#       alias -e ls='ls -Ahl' => '"/bin/ls" -Ahl'
#
#   * Skips alias if command does not exist:
#       alias -e pony='/bin/magic-pony'           => (no alias)
#       alias -e unicorn='magic-pony --with-horn' => (no alias)
#
#   * Transfers any existing completions for a command to the alias:
#     (suppress this feature with `-n`)
#
#       complete -p exec                          => complete -c exec
#       alias -e x='exec' && complete -p x        => complete -c x
#       alias -ne s='sudo' && complete -p s       => (no completions)
#
#   * Returns 1 if command is not found, or an error occurs:
#       alias -e foo='foo --bar'; echo $!         => 1
#
alias() {
    # Short-circuit if leading argument isn't a flag
    if [[ "$1" != -* ]]; then
        builtin alias "$@"
        return $!
    fi

    local OPTIND opt print nocomp
    while getopts :pen opt; do
        case $opt in
        p) print=1;;
        e) :;;
        n) nocomp=1;;
        esac
    done
    shift $((OPTIND-1))

    # Short-circuit if printing aliases
    if ((print)); then
        builtin alias -p "$@"
        return $!
    fi

    local arg
    for arg in "$@"; do
        # If this is not an assignment, we are just printing the alias
        if [[ "$arg" != *=* ]]; then
            builtin alias "$arg" || return 1
            continue
        fi

        # Split argument into name and (array)value; eval preserves user's
        # quoting and escaping
        local name="${arg%%=*}" val
        eval "val=(${arg#*=})"
        local cmd="${val[0]}" opts="${val[*]:1}" ctype

        # Command is a path to an executable
        if [[ -x "$cmd" ]]; then
            builtin alias "$name=\"$cmd\" $opts"
        # Command is in PATH; replace cmd with absolute path
        elif ctype="$(type -t "$cmd")" && [[ "$ctype" == file ]]; then
            builtin alias "$name=\"$(type -P "$cmd")\" $opts"
        # If `type -t` returns anything else than 'file', do a straight alias
        elif [[ "$ctype" ]]; then
            builtin alias "$name=${val[*]}"
        # The command doesn't exist! Return false
        else
            return 1
        fi

        # Alias was successful; transfer completions to the new alias
        if ((!nocomp)); then
            eval $({ complete -p "$cmd" || echo :; } 2>/dev/null) "$name"
        fi
    done
}; GC_FUNC alias


# Magic `cd` wrapper creation:
#
# cdfunc foo /path/to/foo
#
#   * Creates shell variable $foo, suitable for use as an argument:
#
#       $ cp bar $foo/subdir
#
#   * Creates shell function foo():
#
#       $ foo               # Changes working directory to '/path/to/foo'
#       $ foo bar/baz       # Changes working directory to '/path/to/foo/bar/baz'
#
#   * Creates completion function __foo__() which completes foo():
#
#       $ foo <Tab>         # Returns all directories in '/path/to/foo'
#       $ foo bar/<Tab>     # Returns all directories in '/path/to/foo/bar'
#
#   * Does nothing if '/path/to/foo' does not exist or is not a directory
#
# cdfunc -n ... ../..
#
#   * No check for extant directory with `-n`
#
# cdfunc -f cdgems 'ruby -rubygems -e "puts Gem.dir"'
#
#   * Shell variable $cdgems only created after first invocation
#
#   * Lazy evaluation; avoids costly invocations at shell init
#
cdfunc() {
    local OPTIND opt func nocheck
    while getopts :fn opt; do
        case $opt in
        f) func=1;;
        n) nocheck=1;;
        esac
    done
    shift $((OPTIND-1))

    if ((func)); then
        local name="$2" func="$3" dir

        # Set shell variable on first call
        eval "$name() {
            if [[ \"\$$name\" ]]; then
                cd \"\$$name/\$1\"
            else
                cd \"\$($func)/\$1\"
                [[ \"\$$name\" ]] || $name=\"\$PWD\" 2>/dev/null
            fi
        }"
    else
        local name="$1" dir="$2" func

        if ((!nocheck)); then
            [[ -d "$dir" ]] || return 1
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
                    [[ -d \"\$line\" ]] && echo \"\$line/\"
                done
            else
                # Chomp the trailing slash
                base=\"\${cur%/}\"

                # If this directory doesn't exist, try its parent
                [[ -d \"\$base\" ]] || base=\"\${base%/*}\"

                # Return directories
                command ls -A1 \"\$base\" | while read line; do
                    [[ -d \"\$base/\$line\" ]] && echo \"\$base/\$line\"
                done
            fi
        )\"

        local IFS=\$'\\n'
        COMPREPLY=(\$(compgen -W \"\$words\" -- \"\$cur\"))
    }"

    # Complete the shell function
    complete -o nospace -o filenames -F "__${name}__" "$name"
}; GC_FUNC cdfunc


# Magic init script wrapper creation:
#
# initfunc rcd /etc/rc.d
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
#   * Does nothing if '/etc/rc.d' does not exist or is not a directory
#
initfunc() {
    local name="$1" dir="$2"
    [[ -d "$dir" ]] || return

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
}; GC_FUNC initfunc
