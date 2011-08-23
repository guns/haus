### SHELL OPTIONS ###

# POSIX shell options.
#
# Default:
# SHELLOPTS=braceexpand:emacs:hashall:histexpand:history:interactive-comments:monitor
#
set -o braceexpand                      # Perform brace expansion
set -o emacs                            # Emacs editing mode
set -o hashall                          # Hash commands for faster lookup
set -o histexpand                       # ! history expansions
set -o interactive-comments             # Allow comments in interactive shell
set -o monitor                          # Enable job control
set -o notify                           # Allow job reports to interrupt prompt
# OFF
set +o allexport                        # Automatically export all vars/funcs
set +o errexit                          # Exit on non-conditional command failures
set +o errtrace                         # Functions/subshells inherit errexit
set +o functrace                        # Functions/subshells inherit DEBUG/TRACE
#set +o history                         # DO NOT SET HERE!
set +o ignoreeof                        # Require 10 EOFs to exit shell
set +o keyword                          # Allow var assignments after a command
set +o noclobber                        # Don't truncate files via redirection
set +o noexec                           # Non-interactive only dry-run mode
set +o noglob                           # Disable pathname expansion
set +o nolog                            # "Currently ignored"
set +o nounset                          # Disallow use of undeclared variables
set +o onecmd                           # Exit after one command
set +o physical                         # Traverse "real" dirs, not symlinks
set +o pipefail                         # Return errors in pipeline
set +o posix                            # Strict POSIX mode
set +o privileged                       # Slightly more secure mode
set +o verbose                          # Print input lines as they are read
set +o vi                               # vi editing mode
#set +o xtrace                          # DO NOT SET HERE!


# Bash shell options.
#
# Default:
# BASHOPTS=cmdhist:expand_aliases:extquote:force_fignore:hostcomplete:interactive_comments:progcomp:promptvars:sourcepath
#
shopt -s autocd                         # Traverse directories without `cd`
shopt -s cdspell                        # Enable `cd` spelling correction
shopt -s checkhash                      # Use command hash table
shopt -s checkjobs                      # Warn about running jobs before exit
shopt -s checkwinsize                   # Update LINES/COLUMNS after every cmd
shopt -s cmdhist                        # Multiline commands as one history entry
shopt -s dirspell                       # Interactive dir name spell correction
shopt -s dotglob                        # Glob filenames with leading dot
shopt -s expand_aliases                 # Enable aliasing
shopt -s extglob                        # Enable [?*+@!]() pattern matching
shopt -s extquote                       # Allow $'' and $"" in "${var}" expansions
shopt -s force_fignore                  # Always ignore FIGNORE
shopt -s globstar                       # Allow recursive glob with **
shopt -s histappend                     # Append, don't clobber history file
shopt -s histreedit                     # Allow editing of failed history subst
shopt -s histverify                     # Expand history subst on command line
shopt -s hostcomplete                   # Complete hosts when word contains `@`
shopt -s interactive_comments           # Allow comments in interactive shells
#shopt -s login_shell                   # DO NOT SET HERE!
shopt -s mailwarn                       # "Please Mister Postman, look and see"
shopt -s no_empty_cmd_completion        # Don't attempt cmd completion on empty line
shopt -s progcomp                       # Enable programmable completion
shopt -s promptvars                     # Do variable expansion in PS* prompts
shopt -s sourcepath                     # Prepend PWD to filename when sourcing
# OFF
shopt -u cdable_vars                    # Enable var arguments to `cd`
shopt -u compat31                       # Do not respect quoting in [[ =~ ]]
shopt -u compat32                       # Force use of ASCII collation in [[ </> ]]
shopt -u compat40                       # Revert to 4.0 behavior of interrupting a cmd list
shopt -u compat41                       # Use funky POSIX rules regarding "''"
shopt -u execfail                       # Do not exit if exec fails
shopt -u extdebug                       # Extended debug mode
shopt -u failglob                       # Notify on filename expansion error
shopt -u gnu_errfmt                     # Use standard GNU error format
shopt -u huponexit                      # Send SIGHUP to all jobs on exit
shopt -u lastpipe                       # Run last command of pipeline in current shell
shopt -u lithist                        # Save history in multi-line format
shopt -u nocaseglob                     # Case insensitive path globbing
shopt -u nocasematch                    # Case insensitive `case` or `[[`
shopt -u nullglob                       # Failed globs expand to null strings
#shopt -u restricted_shell              # DO NOT SET HERE!
shopt -u shift_verbose                  # Whiny shift failures
shopt -u xpg_echo                       # `echo -e` by default
