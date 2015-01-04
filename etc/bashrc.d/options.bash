###
### SHELL OPTIONS
###

{
    ### POSIX shell options.
    # diff -U3 <(bash --norc --noprofile -ilc "set -o" 2>/dev/null) <(bash -ilc "set -o" 2>/dev/null)
    set +o allexport
    set -o braceexpand
    set -o emacs
    set +o errexit
    set +o errtrace
    set +o functrace
    set -o hashall
    set -o histexpand
    #set -o history                         # DO NOT SET HERE!
    set +o ignoreeof
    set -o interactive-comments
    set +o keyword
    set -o monitor
    set +o noclobber
    set +o noexec
    set +o noglob
    set +o nolog
    set -o notify                           # ✔ Report the status of terminated background jobs immediately
    set +o nounset
    set +o onecmd
    set +o physical
    set +o pipefail
    set +o posix
    set +o privileged
    set +o verbose
    set +o vi
    #set +o xtrace # DO NOT SET HERE!

    ### Bash shell options.
    # diff -U3 <(bash --norc --noprofile -ilc shopt 2>/dev/null) <(bash -ilc shopt 2>/dev/null)
    shopt -s autocd                         # ✔ a command name that is the name of a directory is executed as if it were the argument to the cd command
    shopt -u cdable_vars
    shopt -s cdspell                        # ✔ minor errors in the spelling of a directory component in a cd command will be corrected
    shopt -s checkhash                      # ✔ bash checks that a command found in the hash table exists before trying to execute it
    shopt -s checkjobs                      # ✔ bash lists the status of any stopped and running jobs before exiting an interactive shell
    shopt -s checkwinsize                   # ✔ bash checks the window size after each command and, if necessary, updates the values of LINES and COLUMNS
    shopt -s cmdhist
    shopt -u compat31
    shopt -u compat32
    shopt -u compat40
    shopt -u compat41
    shopt -u compat42
    shopt -s complete_fullquote
    shopt -u direxpand
    shopt -s dirspell                       # ✔ bash attempts spelling correction on directory names during word completion
    shopt -s dotglob                        # ✔ bash includes filenames beginning with a `.' in the results of pathname expansion
    shopt -u execfail
    shopt -s expand_aliases
    shopt -u extdebug
    shopt -s extglob                        # ✔ extended pattern matching features
    shopt -s extquote
    shopt -s failglob                       # ✔ patterns which fail to match filenames during pathname expansion result in an expansion error
    shopt -s force_fignore
    shopt -s globstar                       # ✔ ** used in a pathname expansion context will match all files and zero or more directories and subdirectories. If the pattern is followed by a /, only directories and subdirectories match
    shopt -u gnu_errfmt
    shopt -u globasciiranges
    shopt -s histappend                     # ✔ history list is appended to the file named by the value of the HISTFILE variable when the shell exits, rather than overwriting the file
    shopt -s histreedit                     # ✔ user is given the opportunity to re-edit a failed history substitution
    shopt -s histverify                     # ✔ results of history substitution are not immediately passed to the shell parser
    shopt -s hostcomplete                   # ✔ perform hostname completion when a word containing a @ is being completed
    shopt -u huponexit
    shopt -s interactive_comments
    shopt -u lastpipe
    shopt -u lithist
    #shopt -u login_shell                   # DO NOT SET HERE!
    shopt -u mailwarn
    shopt -s no_empty_cmd_completion        # ✔ bash will not attempt to search the PATH for possible completions when completion is attempted on an empty line
    shopt -u nocaseglob
    shopt -u nocasematch
    shopt -u nullglob
    shopt -s progcomp
    shopt -s promptvars
    #shopt -u restricted_shell              # DO NOT SET HERE!
    shopt -u shift_verbose
    shopt -s sourcepath
    shopt -u xpg_echo
} 2>/dev/null
