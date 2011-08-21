### BASH FUNCTIONS, ALIASES, and VARIABLES ###

### Environment Variables

PATH_ARY=(
    ~/bin                               # User programs
    /usr/local/{,s}bin                  # Local administrator's programs
    /opt/ruby/{1.9,1.8,1.8.6}/bin       # Ruby installations
    {~/.haus,/opt/haus/bin}             # Haus programs
    "$PATH"                             # Existing PATH
    /{,usr/}{,s}bin                     # Canonical Unix PATH
    /opt/brew/{,s}bin                   # Homebrew (OS X)
    /opt/passenger/bin                  # Phusion Passenger
    /usr/{local/,}games                 # Games
); EXPORT_PATH

# Bash history
HISTSIZE='65535'                        # Default: 500
HISTIGNORE='&:cd:..*(.):ls:lc: *'       # Ignore dups, common commands, and leading spaces

# Editor
export EDITOR='vim'
export VISUAL='vim'

# Locales
export LANG='en_US.UTF-8'               # UTF-8 ftw
export LC_CTYPE='en_US.UTF-8'           # Rxvt-unicode needs this set explicitly
export LC_COLLATE='C'                   # Traditional ASCII sorting

# BSD and GNU colors
export CLICOLOR=1
export LSCOLORS='ExFxCxDxbxegedabagacad'
export LS_COLORS='di=01;34:ln=01;35:so=01;32:pi=01;33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:ow=30;42:tw=30;43'
command ls ~ --color &>/dev/null && export GNU_COLOR_OPT='--color'
grep -P . <<< . &>/dev/null      && export GREP_PCRE_OPT='-P'

# Pager
export PAGER='less'
export LESS='--clear-screen --ignore-case --long-prompt --RAW-CONTROL-CHARS --chop-long-lines --tilde --shift 8'
export LESSSECURE=1                     # ++secure
export LESSHISTFILE='-'                 # No ~/.lesshst
export LESS_TERMCAP_md=$'\e[37m'        # Begin bold
export LESS_TERMCAP_so=$'\e[36m'        # Begin standout-mode
export LESS_TERMCAP_us=$'\e[4;35m'      # Begin underline
export LESS_TERMCAP_mb=$'\e[5m'         # Begin blink
export LESS_TERMCAP_se=$'\e[0m'         # End standout-mode
export LESS_TERMCAP_ue=$'\e[0m'         # End underline
export LESS_TERMCAP_me=$'\e[0m'         # End mode

# Ruby
export BUNDLE_PATH="$HOME/.bundle"
[[ $SSH_TTY ]] && export RAILS_ENV='production' RACK_ENV='production'


### Meta

# List all defined functions
showfunctions() { set | grep '^[^ ]* ()'; }

# Transfer completions from src -> dst
tcomp() { eval $({ complete -p "$1" || echo :; } 2>/dev/null) "$2"; }

# Toggle history
nohist() {
    if [[ "$SHELLOPTS" =~ :?history:? ]]; then
        set +o history
    else
        set -o history
    fi
    __ps1toggle__ '/\\w/\\w [nohist]'
}

# Verbose execution
run()   { echo >&2 -e "\e[1;32m$*\e[0m"; "$@"; };                            tcomp exec run
bgrun() { echo >&2 -e "\e[1;33m$* &>/dev/null &\e[0m"; "$@" &>/dev/null & }; tcomp exec bgrun

# Utility timestamp
stamp() { run touch /tmp/timestamp; }

# Report on interesting daemons
services() {
    # We're actually just going to grep the process list
    local processes=(
        apache2 httpd nginx
        php-cgi php-fpm
        mysqld postgres
        named unbound dnsmasq
        exim sendmail
        smbd nmbd nfsd
        sshd
        urxvtd
        wicd
    )

    local p list="$(ps axo ucomm)" retval=1
    for p in "${processes[@]}"; do
        echo "$list" | grep -qw "$p" && echo "$p is ALIVE." && retval=0
    done
    return $retval
}

# List resolver targets
resolv() {
    if type scutil &>/dev/null; then
        run scutil --dns
    elif [[ -r /etc/resolv.conf ]]; then
        run grep -v '^#' /etc/resolv.conf
    else
        echo 'No resolvers file.'; return 1
    fi
}

swap-files() {
    [[ $# -eq 2 && -w "$1" && -w "$2" ]] || {
        echo >&2 'Exactly two writable files expected!'
        return 1
    }

    local tmp=".${1##*/}-SWAPTMP-$RANDOM"
    {   run command mv -- "$1"   "$tmp"
        run command mv -- "$2"   "$1"
        run command mv -- "$tmp" "$2"
    } || return 1
}


### Directories and Init scripts

cdfunc cdhaus       /opt/haus
cdfunc cdhaus       ~/.haus
cdfunc -n ..        ..
cdfunc -n ...       ../..
cdfunc -n ....      ../../..
cdfunc -n .....     ../../../..
cdfunc -n ......    ../../../../..
cdfunc -n .......   ../../../../../..
cdfunc cdetc        /etc
cdfunc cdtmp        /tmp
cdfunc cdvar        /var
cdfunc cdabs        /var/abs
cdfunc cdopt        /opt
cdfunc cdrcd        /usr/local/etc/rc.d
cdfunc cdrcd        /etc/rc.d
cdfunc cdlocal      /usr/local
cdfunc cdsrc        /usr/local/src
cdfunc cdsrc        ~/src
cdfunc cdnginx      /usr/local/etc/nginx
cdfunc cdnginx      /opt/nginx/etc
cdfunc cddnsmasq    /usr/local/etc
cdfunc cddnsmasq    /opt/dnsmasq/etc
cdfunc cdbrew       /opt/brew
cdfunc cdhttp       ~/Sites
cdfunc cdhttp       /srv/www
cdfunc cdhttp       /srv/http
cdfunc cddownloads  ~/Downloads
cdfunc cdappprefs   ~/Library/Preferences
cdfunc cdappsupport ~/Library/Application Support

initfunc rcd        /usr/local/etc/rc.d
initfunc rcd        /etc/rc.d
initfunc initd      /etc/init.d


### Bash builtins

alias -e comp='complete -p'
alias -e cv='command -v'
alias -e d='dirs'
alias -e h='history'
alias -e j='jobs'
alias -e o='echo'
alias -e p='pushd .'
alias -e pp='popd'
alias -e rehash='hash -r'
alias -e t='type'
alias -e ta='type -a'
alias -e x='exec'
alias wrld='while read l; do'; tcomp exec wrld


### Files and Disks

# grep
alias -e g="grep -i $GREP_PCRE_OPT $GNU_COLOR_OPT"
alias -e g3='g -C3'
alias -e gv='g -v'
alias wcl='grep -c .'

# ls
alias -e ls="ls -Ahl $GNU_COLOR_OPT"
alias -e lc='ls -C'
alias -e lsr='ls -R' && lsrl() { ls -R "${@:-.}" | less; }
alias -e lst='ls -t' && lstl() { ls -t "${@:-.}" | less; }
alias -e l1='ls -1'
alias l1g='l1 | g'
alias lsg='ls | g'
__lstype__() {
    ruby -e '
        Dir.chdir ARGV.first do
            puts Dir.entries(".").reject { |e| e =~ /\A\.{1,2}\z/ }.select { |f|
                eval ARGV[1]
            }.sort
        end
    ' "$1" "$2"
}
ls.() { __lstype__ "${1:-.}" 'f =~ /\A\./'; }
lsd() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "directory"'; }
lsl() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "link"'; }

# cat less tail
alias -e c='cat'
alias -e l='less'
alias -e L='less +S' # Softwrap
alias -e lf='less +F' # Follow-forever
alias -e tf='tail -f'
[[ -r /var/log/system.log ]] && {
    alias tfsystem='tf /var/log/system.log'
    alias lfsystem='lf /var/log/system.log'
}
[[ -r /var/log/everything.log ]] && {
    alias tfeverything='tf /var/log/everything.log'
    alias lfeverything='lf /var/log/everything.log'
}

# hexdump strings
alias -e hex='hexdump -C' && hexl() { hexdump -C "$@" | less; }
type strings &>/dev/null && lstrings() { strings -t x - "$@" | less; }

# find
f() {
    local args=() pattern

    if [[ -d "$1" ]]; then
        args+=("$1")
        shift
    else
        args+=(.)
    fi

    if (($#)); then
        if [[ "$1" == -* || "$1" == '(' ]]; then
            args+=("$@")
        else
            case $1 in
            ^*) pattern="${1#^}*";;
            *$) pattern="*${1%$}";;
            *)  pattern="*$1*"
            esac
            args+=(-iname "$pattern" "${@:2}")
        fi
    fi

    run find "${args[@]}"
}; tcomp find f
f1() { f "$@" -maxdepth 1; };               tcomp find f1
ff() { f "$@" \( -type f -o -type l \); };  tcomp find ff
fd() { f "$@" -type d; };                   tcomp find fd
fl() { f "$@" -type l; };                   tcomp find fl
fnewer() { f "$@" -newer /tmp/timestamp; }; tcomp find fnewer
cdf() {
    cd "$(f "$@" -type d -print0 | ruby -e 'print $stdin.gets("\0") || "."' 2>/dev/null)"
}; tcomp find cdf

# cp mv
alias -e cp='cp -v'
alias -e cpr='cp -r'
alias -e mv='mv -v'

# rm
alias -e rm='rm -v'
alias -e rmf='rm -f'
alias -e rmrf='rm -rf'
rm-craplets() {
    run find "${1:-.}" \
        \( -name '.DS_Store' -o -name 'Thumbs.db' \) \
        -type f -print -delete
}

# ln
alias -e ln='ln -v'
alias -e lns='ln -s'
alias -e lnsf='lns -f'
lnnull() { run command rm -rf "${1%/}" && run command ln -sf /dev/null "${1%/}"; }

# chmod chown
alias -e chmod='chmod -v'
alias -e chmodr='chmod -R'
alias -e chmodx='chmod +x'
alias -e chown='chown -v'
alias -e chownr='chown -R'

# mkdir
alias -e mkdir='mkdir -v'
alias -e mkdirp='mkdir -p'

# df / du
alias -e df='df -h'
alias -e du='du -h'
alias -e dus='du -s'
dusort() {
    echo 'Calculating sorted file size...' >&2

    local buf line

    if (($#)); then
        buf="$(f "$@" -print0 | xargs -0 du -s)"
    else
        buf="$(f1 \( ! -name . \) -print0 | xargs -0 du -s)"
    fi

    echo -e "$buf" | sort -n | cut -f2 | while read line; do
        command du -sh -- "$line"
    done
} && tcomp f dusort

# mount
alias -e mt='mount -v'

# tar
alias -e star='tar --strip-components=1'
alias gtar='tar zcv'
alias btar='tar jcv'
alias lstar='tar tvf'
untar() {
    local strip=() f
    [[ "$1" == '-S' ]] && { strip+=(--strip-components=1); shift; }
    [[ -f "$1" ]] && f='f';
    run tar xv$f "$@" "${strip[@]}"
}
suntar() { untar -S "$@"; }

# pax
alias -e gpax='pax -z' && {
    lspax() {
        local zip
        [[ "$1" == *.gz ]] && zip='-z'
        pax "$zip" < "$1"
    }

    unpax() {
        ruby -r fileutils -r shellwords -e '
            abort "Usage: unpax archive basedir" unless ARGV.size == 2

            include FileUtils::Verbose

            archive, basedir = ARGV.take(2).map { |f| File.expand_path f }
            zip = "-z" if File.extname(archive) == ".gz"
            cmd = "pax -r #{zip} < #{archive.shellescape}"

            mkdir_p basedir
            chdir basedir
            puts cmd
            system cmd
        ' "$@"
    }
}

# rsync
alias -e rsync='rsync --human-readable --progress' && {
    # Backup mode is more expensive
    alias -e rsync-mirror='rsync --archive --delete --partial --exclude=.git'
    alias -e rsync-backup='rsync --archive --delete --partial --sparse --hard-links'
}

# dd
alias -e dd3='dc3dd'
alias -e ddc='dcfldd'


### Processes

# kill killall
alias -e k='kill'
alias -e k9='kill -9'
alias -e khup='kill -HUP'
alias -e kint='kill -INT'
alias -e kusr1='kill -USR1'
alias -e kquit='kill -QUIT'
alias -e ka='killall -v' && {
    alias -e ka9='ka -9'
    alias -e kahup='ka -HUP'
    alias -e kaint='ka -INT'
    alias -e kausr1='ka -USR1'
    alias -e kaquit='ka -QUIT'
}

# ps (traditional BSD / SysV flags seem to be the most portable)
tcomp kill ps
alias -e p1='ps axo comm'
alias -e psa='ps axo ucomm,pid,ppid,pgid,pcpu,pmem,state,user,group,command'
alias psg='psa | grep -v "grep -i" | g'
# BSD-style ps supports `-r` and `-m`
if ps ax -r &>/dev/null; then
    alias psr='psa -r | sed 11q'
    alias psm='psa -m | sed 11q'
# Linux ps supports `k` and `--sort`
elif ps ax kpid &>/dev/null; then
    alias psr='psa k-pcpu | sed 11q'
    alias psm='psa k-rss | sed 11q'
fi
alias psal='psa | less'
alias psrl='psr | less'
alias psml='psm | less'


### Switch User

alias -e s='sudo' && root() { run exec sudo su; }
type su &>/dev/null && alias xsu='exec su'


### Network

alias -e ic='ifconfig'
alias -e arplan='arp -lan'

# cURL
alias -e get='curl -#L'

# DNS
alias -e digx='dig -x'

# netcat
type nc   &>/dev/null && tcomp host nc
type ncat &>/dev/null && tcomp host ncat

# ssh scp
# http://blog.urfix.com/25-ssh-commands-tricks/
alias -e ssh='ssh -C -2' && {
    alias -e sshx='ssh -XY' # WARNING: trusted forwarding!
    alias -e ssh-shell="exec ssh-agent \"$SHELL\""
    alias -e ssh-master='ssh -Nn -M' # ControlMaster connection
    alias -e ssh-tunnel='ssh -Nn -M -D 22222'
    alias -e ssh-password='ssh -o "PreferredAuthentications password"'
    alias -e ssh-nocompression='ssh -o "Compression no"'
    type ssh-proxy &>/dev/null && tcomp ssh ssh-proxy

    alias -e scp='scp -C -2' && {
        alias -e scpr='scp -r'
    }
}

# lsof
alias -e lsif='lsof -Pni' && {
    alias lsifudp='lsof -Pni | grep UDP'
    alias lsiflisten='lsof -Pni | grep LISTEN'
    alias lsifconnect='lsof -Pni | grep -- "->"'
}

# nmap
type nmap &>/dev/null && {
    type getlip &>/dev/null &&
    nmapsweep() { run nmap -sP -PPERM $(getlip)/24; }
    nmapscan() { run nmap -sS -A "$@"; }
    tcomp nmap nmapscan
}


### Editors

# Ctags
alias -e ctags='ctags -f .tags' && {
    alias -e ctagsr='ctags -R'
}

# Vim
alias -e vim='vim -p' && {
    alias -e v='vim'
    alias -e vi='command vim -u NONE'
    alias -e vimtag='vim -t'
    alias -e vimlog='vim -V/tmp/vim.log'
    vimfind() {
        local files=()
        (($#)) && {
            local IFS=$'\n'
            files=($(ff "$@" 2>/dev/null))
            unset IFS
        }

        if (( ${#files[@]} )); then
            vim -p "${files[@]}"
        else
            vim -c 'CommandT'
        fi
    } && tcomp find vimfind

    # Explore man pages in vim
    alias -e mman='command man'
    man() {
        local i sec page pages=0 args=()

        for ((i=1; i<=$#; ++i)); do
            page="${@:i:1}"
            sec=''

            if [[ $page == +([0-9]) ]]; then
                sec="$page"
                ((++i))
                page="${@:i:1}"
            fi

            command man -w "$page" || continue

            if ((pages++)); then
                args+=(-c "tabedit | OMan $sec $page")
            else
                args+=(-c "OMan $sec $page")
            fi
        done

        (( ${#args[@]} )) && run vim -p "${args[@]}"
    }

    # Open fugitive straight from command line
    vimgit() { vim -c 'Gstatus' .; }

    # Git[vV] wrapper
    gitv() {
        if [[ -f "$1" ]]; then
            vim -c "Gitv!" "$1"
        else
            vim -c 'Gitv' -c 'tabonly' .
        fi
    }

    # Open in REPL mode with the screen.vim plugin
    vimrepl() {
        case $# in
        2) local file="$1" cmd="$2";;
        1) local file="$1";;
        0) local file='vimrepl';;
        *) return 1
        esac

        echorun vim -c "Screen $cmd" "$file"
    }

    # server / client functions
    # (be careful; vim clientserver is a huge security hole)
    [[ $EUID -ne 0 ]] && {
        vimserver() {
            local name='editserver'
            if (($# == 0)); then
                vim --servername $name
            elif [[ $1 == -w ]]; then
                vim --servername $name --remote-tab-wait "${@:1}"
            else
                vim --servername $name --remote-tab "$@"
            fi
        }

        vimstartuptime() {
            (sleep 3 && vimserver '.vimstartuptime' && (sleep 3 && rm -f '.vimstartuptime') & ) &
            vim --servername 'editserver' --startuptime '.vimstartuptime' "$@"
        }
    }

    # frequently edited files
    [[ -d "$cdnerv" ]] && {
        alias vimrc='(cdnerv; exec vim etc/user.vimrc)'
        alias vimautocommands='(cdnerv; exec vim etc/user.vim/local/autocommands.vim)'
        alias vimcommands='(cdnerv; exec vim etc/user.vim/local/commands.vim)'
        alias vimmappings='(cdnerv; exec vim etc/user.vim/local/mappings.vim)'
        alias vimprofile='(cdnerv; exec vim etc/nerv_profile)'
        alias vimsubtle='(cdnerv etc/user.subtle; exec vim subtle.rb)'
    }
    [[ -d "$cdnginx" ]] && alias vimnginx='(cdnginx; exec vim nginx.conf)'
    alias vimscratch='vim -c Scratch'
    alias vimorg='vim -c Org!'
    alias vimtodo='vim -c "Org! TODO"'
}

: # Return true
