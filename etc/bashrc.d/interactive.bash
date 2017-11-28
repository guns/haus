###
### BASH FUNCTIONS, ALIASES, and VARIABLES
###
### Requires ~/.bashrc.d/functions.bash
###

### Utility Functions

# Toggle PS1 transformations
# Param: $* Interior of bash parameter expansion: '/\\u/\\u is a luser'
__ps1toggle__() {
    # Seed PS1 stack variable if unset
    declare -p __ps1stack__ &>/dev/null || __ps1stack__=("$PS1")

    # Check for existing transformation
    local idx count=${#__ps1stack__[@]} exists=0
    for ((idx = 1; idx < count; ++idx)); do
        if [[ "$*" == "${__ps1stack__[idx]}" ]]; then
            exists=1
            break
        fi
    done

    # Remove existing pattern, or push new one
    if ((exists)); then
        __ps1stack__=("${__ps1stack__[@]:0:idx}" "${__ps1stack__[@]:idx+1}")
    else
        __ps1stack__+=("$*")
    fi

    # Replay transformations
    local expr
    PS1="${__ps1stack__[0]}"
    for expr in "${__ps1stack__[@]:1}"; do
        eval "PS1=\"\${PS1$expr}\""
    done
}

# Param: $1       PATH-style envvar name
# Param: [${@:2}] List of directories to prepend
__prepend_path__() {
    local var="$1"

    if (($# == 1)); then
        ruby -e 'puts [ARGV[0], ENV[ARGV[0]]].join("=")' -- "$var"
        return
    fi

    local dir newpath
    for dir in "${@:2}"; do
        if newpath="$(ruby -e '
            paths = (ENV[ARGV[0]] || "").split ":"
            dir = File.expand_path ARGV[1]
            abort unless File.directory? dir
            puts paths.reject { |d| d == dir }.unshift(dir).join(":")
        ' -- "$var" "$dir")"; then
            export "$var=$newpath"
            echo "$var=$newpath"
        fi
    done
}

# Param: $1 Directory to list
# Param: $2 Interior of Ruby block with filename `f`
__lstype__() {
    ruby -e '
        Dir.chdir ARGV.first do
            puts Dir.entries(".").reject { |e| e =~ /\A\.{1,2}\z/ }.select { |f| eval ARGV[1] }.sort
        end
    ' -- "$@"
}

### Completion Functions

__longopt__() {
    complete -F _longopt "$@"
}

__compreply__() {
    local cur
    _get_comp_words_by_ref cur
    COMPREPLY=($(compgen -W "$*" -- "$cur"));
}

__cryptnames__() {
    __compreply__ "$(cat /sys/block/*/dm/name)"
}

__lsdisk__() {
    __compreply__ "$(lsdisk)"
}

__partitions__() {
    __compreply__ "$(awk 'NR > 2 {print "/dev/"$NF}' /proc/partitions)"
}

__api__() {
    __compreply__ "$(command ls -1 "$cdapi")"
}

__pacdowngrade__() {
    __compreply__ "$(command ls -1 /var/cache/pacman/pkg/ | grep '\.tar.xz$')"
}

__mtlabel__() {
    if ((COMP_CWORD == 1)); then
        __compreply__ "$(command ls -1 /dev/disk/by-label/)";
    else
        type _mount &>/dev/null || __load_completion mount
        _mount
    fi
}

__mtusb__() {
    local prev
    _get_comp_words_by_ref prev
    if [[ "$prev" == '-o' || "$prev" == '--options' ]]; then
        type _mount &>/dev/null || __load_completion mount
        _mount
    fi
}

__cx__() {
    if ((COMP_CWORD == 1)); then
        __compreply__ "$(command ls -1 /etc/ca-certificates/trust-source/anchors/ | grep '\.crt$')";
    else
        _command_offset 2
    fi
}

__rackenv__() {
    __compreply__ production development testing
}

__systemd_units__() {
    __compreply__ "$({ systemctl list-unit-files; systemctl list-units --all; } | while read -r a b; do
        [[ $a =~ @\. ]] || echo " $a"
    done)"
}

### DIRECTORYBINDINGS

CD_FUNC -n ..           ..
CD_FUNC -n ...          ../..
CD_FUNC -n ....         ../../..
CD_FUNC -n .....        ../../../..
CD_FUNC -n ......       ../../../../..
CD_FUNC -n .......      ../../../../../..
CD_FUNC -n ........     ../../../../../../..
CD_FUNC -x cdhaus       ~/.haus /opt/haus
CD_FUNC -x cdetc        /etc
CD_FUNC cdinit          /etc/{rc,init}.d /usr/local/etc/{rc,init}.d
CD_FUNC cdanchors       /etc/ca-certificates/trust-source/anchors
CD_FUNC cdmnt           /mnt
CD_FUNC -x cdnginx      /etc/nginx
CD_FUNC cdtmp           ~/tmp "$TMPDIR" /tmp
CD_FUNC cdTMP           /tmp
CD_FUNC cdvar           /var
CD_FUNC cdmachines      /var/lib/machines
CD_FUNC cdpostgres      /var/lib/postgres
CD_FUNC cdlog           /var/log
CD_FUNC cdpacmancache   /var/cache/pacman/pkg
CD_FUNC cdwww           /srv/http /srv/www /var/www
CD_FUNC -x cdapi        "$cdwww/api.dev"
CD_FUNC -x cdgunsrepl   "$cdhaus/etc/_local/_lib/clojure/guns"
CD_FUNC cdconfig        ~/.config
CD_FUNC cdlocal         ~/.local /usr/local
CD_FUNC cdLOCAL         /usr/local
CD_FUNC cdgo            "${GOPATH%%:*}" /opt/src/go
CD_FUNC cdpass          ~/.password-store
CD_FUNC -x cdsrc        /opt/src ~/src /usr/local/src
CD_FUNC cdSRC           "$cdsrc/READONLY"
CD_FUNC cdarchlinux     "$cdsrc/archlinux"
CD_FUNC cdvimfiles      "$cdsrc/vimfiles"
CD_FUNC cdjdk           "$cdSRC/openjdk/src/share"
CD_FUNC cddesktop       ~/Desktop ~guns/Desktop
CD_FUNC cddocuments     ~/Documents ~guns/Documents
CD_FUNC cddownloads     ~/Downloads ~guns/Downloads

### Bash builtins and Haus commands

# Show commands shadowed by aliases and functions
shadowenv() {
    local cmd buf

    cat <(alias | ruby -e 'puts $stdin.read.scan(/^alias (.*?)=/).map { |(a)| a }') \
        <(set | grep '^[^ ]* ()' | awk '{print $1}') |
    while builtin read cmd; do
        buf="$(type -a "$cmd" | grep "$cmd is ")"
        if (($(grep --count . <<< "$buf") > 1)); then
            printf "%s\n\n" "$buf"
        fi
    done
}

hausrelink() { run haus unlink -b "$@" && run haus link "$@"; }; TCOMP haus hausrelink

alias bashnilla='env --ignore-environment bash --norc --noprofile'
ALIAS cv='command -v'
alias h='history'
alias j='jobs'
alias o='echo'
alias rehash='hash -r'
ALIAS t='type --' \
      ta='type -a --' \
      tp='type -P --'
ALIAS x='exec'
alias wrld='while read l; do'; TCOMP exec wrld
ALIAS comp='complete -p'

# PATH prefixing functions
path()   { __prepend_path__ PATH            "$@"; }
ldpath() { __prepend_path__ LD_LIBRARY_PATH "$@"; }
gopath() { __prepend_path__ GOPATH          "$@"; }

# Toggle xtrace, verbose mode
setx() {
    if [[ "$SHELLOPTS" =~ :?xtrace:? ]]; then
        set +xv
    else
        set -xv
    fi
}

# Toggle history
nohist() {
    if [[ "$HISTFILE" ]]; then
        HISTFILE_DISABLED="$HISTFILE"
        unset HISTFILE
    else
        HISTFILE="${HISTFILE_DISABLED:-$HOME/.bash_history}"
        unset HISTFILE_DISABLED
    fi
    __ps1toggle__ '/\\H/[nohist] \\H'
}
((NOHIST == 1)) && nohist

# Repeat
r() {
    for ((i = 0; i < "$1"; ++i)); do
        "${@:2}"
    done
}

# notify
HAVE notify && {
    n() {
        local exitstatus=$?
        if (($#)); then
            notify "$@"
        else
            notify -? "$exitstatus"
        fi
    }
    alias na='notify --alert'
    __longopt__ notify n na
}

# run bgrun
HAVE run   && TCOMP exec run
HAVE bgrun && TCOMP exec bgrun

### Files, Disks, and Memory

# grep
ALIAS g="grep --ignore-case --color $(grep --perl-regexp . <<< . &>/dev/null && printf %s --perl-regexp)" \
      gw='g --word-regexp' \
      gv='g --invert-match' \
      gc='grep --count .'

# ripgrep
ALIAS rgi='rg --ignore-case' \
      rgf='rg --fixed-strings' \
      rgu='rg -uuu' \
      rgiu='rg --ignore-case -uuu'

# cat tail less
alias c='cat'
alias tf='tail --follow=name --retry'
alias l='less'
alias L='less -+S'
alias lf='less +F'

# syslog follow
if [[ -e /var/log/everything.log ]]; then
    ALIAS lfsyslog='less +F --follow-name /var/log/everything.log'
    alias tfsyslog='tail --follow=name --retry /var/log/everything.log'
elif [[ -e /var/log/system.log ]]; then
    ALIAS lfsyslog='less +F --follow-name /var/log/system.log'
    alias tfsyslog='tail --follow=name --retry /var/log/system.log'
elif [[ -e /var/log/syslog ]]; then
    ALIAS lfsyslog='less +F --follow-name /var/log/syslog'
    alias tfsyslog='tail --follow=name --retry /var/log/syslog'
elif [[ -e /var/log/messages ]]; then
    ALIAS lfsyslog='less +F --follow-name /var/log/messages'
    alias tfsyslog='tail --follow=name --retry /var/log/messages'
fi

# ls
alias ls="ls -l --almost-all --human-readable --quoting-style=literal --show-control-chars --color"
alias lc="command ls -C --color"
alias lsd='ls --directory'
lsr() { ls --recursive "${@:-.}" | pager; }
lst() { ls -t "${@:-.}" | pager; }
alias l1='command ls -1'
alias l1g='l1 | g'
alias l1gv='l1 | gv'
alias lsg='ls | g'
alias lsgv='ls | gv'
alias lsmapper='ls /dev/mapper'
alias lsid='ls /dev/disk/by-id'
alias lslabel='ls /dev/disk/by-label'
alias lspartlabel='ls /dev/disk/by-partlabel'
alias lsuuid='ls /dev/disk/by-uuid'
alias lspartuuid='ls /dev/disk/by-partuuid'
alias lspath='ls /dev/disk/by-path'
alias lsdbus='find /usr/share/dbus-1 -name "*.service" | sort'
ls.() { __lstype__ "${1:-.}" 'f =~ /\A\./'; }
lsl() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "link"'; }
lsx() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "file" and File.executable? f'; }
lsD() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "directory"'; }

# objdump hexdump strings readelf hexfiend
HAVE hexdump && { hex() { hexdump --canonical "$@" | pager; }; TCOMP hexdump hex; }
HAVE objdump && {
    ox() { objdump --all-headers "$@" | pager; }; TCOMP objdump ox
    disas() { objdump -D -M intel-mnemonic "$@" | pager; }
}
HAVE readelf && { dylibs() { readelf --dynamic "$@" | pager; }; TCOMP readelf dylibs; }
HAVE strings && strings() { command strings --all --radix=x "$@" | pager; }

# find
f()  { find-wrapper                                      -- "$@"; }; TCOMP find f
f1() { find-wrapper --predicate '-maxdepth 1'            -- "$@"; }; TCOMP find f1
ff() { find-wrapper --predicate '( -type f -o -type l )' -- "$@"; }; TCOMP find ff
fF() { find-wrapper --predicate '-type f'                -- "$@"; }; TCOMP find fF
fx() { find-wrapper --predicate '-type f -executable'    -- "$@"; }; TCOMP find fx
fl() { find-wrapper --predicate '-type l'                -- "$@"; }; TCOMP find fl
fL() { find-wrapper --predicate '-xtype l'               -- "$@"; }; TCOMP find fL
fd() { find-wrapper --predicate '-type d'                -- "$@"; }; TCOMP find fd
f.() {
    local f
    for d in .*; do
        [[ -d "$d" ]] || continue
        [[ "$d" == . || "$d" == .. ]] && continue
        f "$d" "$@" 2>/dev/null
    done
}; TCOMP find f.
fft() {
    local OPTIND OPTARG opt print0=0
    while getopts :0 opt; do
        case "$opt" in
        0) print0=1;;
        esac
    done
    shift $((OPTIND-1))
    find-wrapper --predicate '( -type f -o -type l ) -print0' -- "$@" | ruby -e '
        xs = $stdin.read.split("\0").sort_by { |f| File.mtime f }.reverse
        puts ARGV[0] == "0" ? xs : xs.join("\0")
    ' "$print0"
}; TCOMP find fft
alias fft0='fft -0'; TCOMP find fft0

# Breadth-first search and chdir
cdf() { cd "$(if ! find-directory "$@"; then echo .; fi)"; }

# cd physical path
cdp() { cd "$(pwd -P)"; }

# xargs
alias x0='xargs -0'

# cp
alias cp='command cp --verbose --interactive'
alias cpf='command cp --verbose --force'
alias cpr='command cp --verbose --recursive --interactive'
alias cprf='command cp --verbose --recursive --force'
alias cpparents='command cp --verbose --parents'

# mv
alias mv='command mv --verbose --interactive'
alias mvf='command mv --verbose --force'

# rm
alias rm='rm --verbose'
alias rmf='rm --force'
alias rmrf='rm --recursive --force --one-file-system'

# ln
alias ln='ln --verbose --interactive'
alias lns='ln --symbolic'
alias lnsf='lns --force'
lndesktop() {
    (($# == 1)) && [[ -L ~/Desktop || ! -e ~/Desktop ]] && [[ -d "$1" ]] && lnrelative --force "$1" ~/Desktop
}
lnnull() { run rm --recursive --force "${1%/}" && run ln --symbolic --force /dev/null "${1%/}"; }

# chmod chown touch
alias chmod='chmod --verbose'
alias chmodr='chmod --recursive'
alias chmodx='chmod +x'
alias chown='chown --verbose'
ALIAS chownr='chown --recursive'

# mkdir
alias md='mkdir --verbose --parents'; complete -o dirnames md
alias rd='rmdir --verbose --parents'; complete -o dirnames rd

# df du
alias df='df --human-readable'
alias du='du --human-readable'
alias dus='du --summarize'

# mount
mt() {
    if (($#)); then
        run mount --verbose --options noatime "$@"
    else
        mount --verbose
    fi
}; TCOMP mount mt
ALIAS mtb='mt --bind'
ALIAS mtro='mt --read-only'
ALIAS mtbro='mt --bind --read-only'
ALIAS umt='umount --verbose'
remt() {
    if (($#)); then
        run mount --verbose --options "remount,$1" "${@:2}"
    else
        echo "USAGE: $FUNCNAME mount-opts mountpoint"
        return 1
    fi
}; TCOMP umount remt
alias mtusb='mountusb'; complete -F __mtusb__ mtusb
alias umtusb='umountusb'
mtlabel() {
    (($# >= 2)) || { echo "$FUNCNAME label mount-args" >&2; return 1; }
    run mount --options noatime "/dev/disk/by-label/$1" "${@:2}"
}; complete -F __mtlabel__ mtlabel

# findmnt
ALIAS fm='findmnt'

# fusermount
ALIAS fusemt='fusermount -o noatime' \
      fuseumt='fusermount -u'

# tar
alias star='tar --strip-components=1'
alias gtar='tar --gzip --create --verbose'
alias btar='tar --bzip2 --create --verbose'
alias xtar='tar --xz --create --verbose'
alias lstar='tar --list --verbose --file'
untar() {
    local opts=() file
    [[ "$1" == --strip-components=* ]] && { opts+=("$1"); shift; }
    [[ -f "$1" ]] && file='--file';
    run tar --extract --verbose $file "$@" "${opts[@]}"
}
suntar() { untar --strip-components=1 "$@"; }
guntar() { untar --gunzip "$@"; }
buntar() { untar --bzip2 "$@"; }
xuntar() { untar --xz "$@"; }

# open
alias op='open 2>/dev/null'

# rsync
ALIAS rsync='rsync -hhh --sparse --partial' && TCOMP rsync rsync-backup

# dd
ALIAS dd='dcfldd' && TCOMP dd dcfldd
HAVE ddsize       && TCOMP dd ddsize

# free
ALIAS free='free --human'

# iotop
ALIAS iotop='iotop --only'

# Linux /proc /sys
[[ -w /proc/sys/vm/drop_caches ]] && drop_caches() {
    local cmd='echo 3 > /proc/sys/vm/drop_caches'
    echo "$cmd"
    eval "$cmd"
}
[[ -e /proc/sys/kernel/sysrq ]] && sysrq() {
    if (($#)); then
        echo "$@" > /proc/sys/kernel/sysrq
    else
        cat /proc/sys/kernel/sysrq
    fi
}

# Swap
ALIAS swapin='swapoff --all --verbose; swapon --all --verbose'

# attributes
ALIAS ls@='lsattr -a'
ALIAS chimmutable='chattr -V +i' \
      chmutable='chattr -V -i'

# inotifywait
ALIAS ino='inotifywait' && fwatch() {
    while inotifywait -q -e attrib -e close_write "$1"; do eval "${@:2}"; sleep 0.5; done
}

# Check shell init files and system paths for loose permissions
ckperm() {
    # path:user:group:octal-mask:opt1,opt2
    local specs=(
        /boot:::0077:no-recurse
        /boot

        /etc
        /etc/crypttab:::0077
        /etc/pacman.d/gnupg/*.d/:::0077:glob
        /etc/pacman.d/gnupg/secring*:::0077:glob
        /etc/ssh/*key:::0077:glob
        /etc/ssl/private:::0077
        /etc/sudoers*::root:0027:glob
        /etc/**/.git:::0077:glob,no-recurse

        /var/lib/{machines,container}:::0077:no-recurse
        /var/lib/systemd/random-seed:::0077

        ~:"$USER"::0077:no-recurse
        ~/.bashrc
        ~/.bash_profile
        ~/.bash_login
        ~/.profile
        ~/.bash_logout
        ~/.bashrc.d
        ~/.rlwrap:::0077
        ~/.*_history:::0077:glob
        ~/.bash_completion
        ~/.bash_completion.d
        ~/.bash_local
        ~/.inputrc
        ~/.mitmproxy:::0077
        ~/.password-store:::0077
        ~/.rnd:::0177
        ~/.ssh:::0077:no-recurse
        ~/.ssh/*_{dsa,ecdsa,ed25519,rsa}:::0077:glob
        ~/.*/.git:::0077:glob,no-recurse
        ~/.config/**/.git:::0077:glob,no-recurse
        ~/.mozilla/**/.git:::0077:glob,no-recurse

        "$BASH_ENV"
        "$ENV"
        "$HISTFILE"
        "$HOSTFILE"
        "$INPUTRC"
        "$MAIL"
        "$TMPDIR"
        "${COPROC[@]}"
        "${MAPFILE[@]}"
    )

    # Swapfiles
    local f
    for f in $(sed '1d; s/\(^[^ ]*\).*/\1/' '/proc/swaps'); do
        specs+=("$f":::0177)
    done

    local IFS=':'
    specs+=($PATH $LD_LIBRARY_PATH ${BASH_COMPLETION_DIRS[@]} $MAIL $MAILPATH)
    unset IFS

    checkpermissions "$@" -- "${specs[@]}"
}

### Processes

# kill
ALIAS k='kill' \
      k9='kill -KILL' \
      khup='kill -HUP' \
      kint='kill -INT' \
      kstop='kill -STOP' \
      kcont='kill -CONT' \
      kusr1='kill -USR1' \
      kquit='kill -QUIT' \
      kabort='kill -ABRT'
ALIAS ka='killall --exact --verbose' \
      ka9='ka -KILL' \
      kahup='ka -HUP' \
      kaint='ka -INT' \
      kastop='ka -STOP' \
      kacont='ka -CONT' \
      kausr1='ka -USR1' \
      kaquit='ka -QUIT' \
      kaabort='ka -ABRT'
ALIAS pk='pkill --exact' \
      pk9='pk -KILL' \
      pkhup='pk -HUP' \
      pkint='pk -INT' \
      pkstop='pk -STOP' \
      pkcont='pk -CONT' \
      pkusr1='pk -USR1' \
      pkquit='pk -QUIT' \
      pkabort='pk -ABRT'

# ps (traditional BSD / SysV flags seem to be the most portable)
alias p1='ps axo comm'
alias psa='ps axo comm,pid,ppid,pgid,sid,nlwp,pcpu,pmem,rss,start_time,user,tt,ni,pri,stat,args'
psg() {
    psa | ruby -e '
        header = $stdin.readline
        lines = $stdin.readlines.grep(Regexp.new ARGV[0]).reject { |l| l =~ /\b#{$$}\b/ }
        abort if lines.empty?
        puts header
        puts lines
    ' -- "$*" | pager
}
alias psgv='psa | grep --invert-match "grep --ignore-case" | gv'
# BSD ps supports `-r` and `-m`
if ps ax -r &>/dev/null; then
    psr() { psa -r "$@" | pager; }
    psm() { psa -m "$@" | pager; }
# GNU/Linux ps supports `k` and `--sort`
else
    psr() { psa k-pcpu "$@" | pager; }
    psm() { psa k-rss  "$@" | pager; }
fi

# pstree
ALIAS pst='pstree'

# htop: Satisfy ncurses hard-coded TERM names
HAVE htop && alias htop='envtmux htop'
HAVE nmon && alias nmon='NMON=vld- nmon'

### Documentation

ALIAS info='info --vi-keys'

### Switch User

ALIAS s='sudo --set-home' \
      asguns='sudo --set-home --user guns'
HAVE su && alias xsu='exec su' && TCOMP su xsu

### Network

# ip
HAVE ip && alias a='ip addr'

# ifconfig
HAVE ifconfig && alias ic='ifconfig'

# netctl
ALIAS net='netctl' \
      netstop='netctl stop-all'

# cURL
TCOMP curl get
ALIAS geto='get --remote-name'

# dig
ALIAS digx='dig -x' \
      digshort='dig +short'

# DNS resolvers
resolv() {
    {
        [[ -e /etc/resolv.conf ]] && {
            printf "\e[32;1m/etc/resolv.conf\e[0m\n"
            cat /etc/resolv.conf
        }
        [[ -e /etc/dnsmasq.resolv.conf ]] && {
            printf "\n\e[32;1m/etc/dnsmasq.resolv.conf\e[0m\n"
            cat /etc/dnsmasq.resolv.conf
        }
    } | grep --invert-match --perl-regexp '^#|^\s*$'
}

# NTP
ALIAS qntp='ntpd -g -q'

# netcat
HAVE nc   && complete -F _known_hosts nc
HAVE ncat && complete -F _known_hosts ncat

# tcpdump
HAVE tcpdump && {
    alias pcapdump='tcpdump -A -r'
}

# ssh scp
ALIAS ssh='ssh -2' \
      ssh-password='ssh -o "PreferredAuthentications password"' && {
    alias ssh-remove-host='ssh-keygen -R' && complete -F _known_hosts ssh-remove-host
    alias ssh-pubkey='ssh-keygen -y -f'
    ssh-keygen-wrapper() {
        (($# == 1)) || { echo "USAGE: $FUNCNAME basename" >&2; return 1; }
        ssh-keygen -b 4096 -N "$(passnew "ssh/${1}_rsa")" -C "${1}_rsa" -f ~/.ssh/"${1}_rsa"
        cat ~/.ssh/"${1}_rsa.pub"
    }
    ssh-bits() {
        local f fs=()
        if (($#)); then
            fs+=("$@")
        else
            fs+=(~/.ssh/*.pub)
        fi
        for f in "${fs[@]}"; do
            printf "%s\t%s\n" "$f" "$(ssh-keygen -l -f "$f")"
        done | table
    }
}
ALIAS scp='scp -2' \
      scpr='scp -r'

# sshuttle
HAVE sshuttle         && TCOMP ssh sshuttle
HAVE sshuttle-proxy   && TCOMP ssh sshuttle-proxy
HAVE sshuttle-domains && TCOMP ssh sshuttle-domains

# lsof
HAVE lsof && {
    command lsof +fg -h &>/dev/null && LSOF_FLAG_OPT='+fg'
    ALIAS lsof="lsof +c0 -Pwn $LSOF_FLAG_OPT"
    alias lsif='lsof -i'
    alias lsifr="command lsof +c0 -Pwi $LSOF_FLAG_OPT"
    alias lsifudp='lsif | grep UDP'
    alias lsiflisten='lsif | grep --word-regexp "LISTEN\|UDP"'
    alias lsifconnect='lsif | grep -- "->"'
    alias lsifconnectr='lsifr | grep -- "->"'
    alias lsuf='lsof -U'
    needs-restarting() {
        ruby -e 'puts %x(lsof +c0).lines.select { |l|
            "%-32s%s" % [$1, $2] if l =~ %r[^(\S+).*\s(/usr/.*) \(deleted\)$]
        }.sort'
    }
    unset LSOF_FLAG_OPT
}

# nmap
ALIAS nmapsweep='nmap -sU -sS --top-ports 50 -O -PE -PP -PM "$(cidr)"'

# ngrep
ALIAS ngg='ngrep -c 0 -d any -l -q -P "" -W byline'

# Weechat
HAVE weechat && ((EUID > 0)) && alias irc='(cd ~/.weechat && envtmux weechat)'

# Local api server @ `$cdapi`
HAVE cdapi && {
    # Param: $@ API Site names
    api() { local d; for d in "$@"; do open "http://${cdapi##*/}/$d"; done; }
    complete -F __api__ api
}

# mitmproxy
alias localmitmproxy='envtmux localmitmproxy'

### Firewalls

# iptables
ALIAS iptables.sh='/etc/iptables.sh'
alias iptw='ipt --wait'
alias ipt6='ipt --ipv6'

### Editors

# Exuberant ctags
ALIAS ctagsr='ctags --recurse'

# Vim
ALIAS e='vim' && {
    alias v='vim -c "set nomodified" -'

    vimopen() { vim -c 'DeniteOpen' "$@"; }

    # Param: [$@] Arguments to `ff()`
    vimfind() {
        local files=()
        if (($#)); then
            local IFS=$'\n'
            files=($(ff "$@" 2>/dev/null))
            unset IFS
        fi

        if (( ${#files[@]} )); then
            vim "${files[@]}"
        else
            vim -c 'Denite file_rec'
        fi
    }; TCOMP find vimfind

    # Vim-ManPage
    alias mman='command man'; TCOMP man mman
    # Param: $@ [[section] command] ...
    man() {
        local i sec page pages=0 args=()

        for ((i=1; i<=$#; ++i)); do
            page="${@:i:1}"
            sec=''

            if [[ "$page" == +([0-9]) ]]; then
                sec="$page"
                ((++i))
                page="${@:i:1}"
            fi

            command man --where "$page" || continue

            if ((pages++)); then
                args+=(-c "tabedit | OMan $sec $page")
            else
                args+=(-c "OMan $sec $page")
            fi
        done

        (( ${#args[@]} )) && run vim "${args[@]}"
    }

    vimsession() {
        local session="$HOME/.cache/vim/session/$(pwd)/Session.vim"
        if [[ -e "$session" ]]; then
            vim -S "$(ruby -rshellwords -e "print ARGV[0].shellescape" "$session")" -c "silent! execute '! rm --force ' . fnameescape(v:this_session)" "$@"
        else
            vim "$@"
        fi
    }

    # vim-fugitive
    alias vimgit='vim -c "call fugitive#detect(\".\") | Gstatus"'
    # Param: [$1] File to browse
    gitv() {
        if [[ -f "$1" ]]; then
            vim -c 'call fugitive#detect(".") | Gitv!' "$1"
        else
            vim -c 'call fugitive#detect(".") | Gitv!'
        fi
    }

    # Open in REPL mode with the screen.vim plugin
    # Param: [$1] Filename
    # Param: [$2] Interpreter to run
    vimrepl() {
        local file cmd

        case $# in
        2) file="$1" cmd="$2";;
        1) file="$1";;
        0) file='vimrepl';;
        *) return 1
        esac

        run vim -c "Screen $cmd" "$file"
    }

    # Param: [$@] Arguments to vim
    vimstartuptime() {
        vim --startuptime /tmp/.vimstartuptime "$@" -c 'quitall!'
        urxvt-client -e vim /tmp/.vimstartuptime
    }

    vimsysctl() {
        (cd /etc/; vimdiff /etc/sysctl.d/99-sysctl.conf <(sysctl -a | sed "s/^/# /") -c "windo setf sysctl")
    }

    alias xterm-color-table='vim -c OXtermColorTable'

    # VIMEDITBINDINGS
    alias vimautocommands='vim "$cdhaus/etc/vim/local/autocommands.vim" -c "lcd \$cdhaus"'
    alias vimabook='vim ~/.abook/addressbook -c "lcd ~/.abook"'
    alias vimbashinteractive='vim "$cdhaus/etc/bashrc.d/interactive.bash" -c "lcd \$cdhaus"'
    alias vimbashrc='vim "$cdhaus/etc/bashrc" -c "lcd \$cdhaus"'
    alias vimcommands='vim "$cdhaus/etc/vim/local/commands.vim" -c "lcd \$cdhaus"'
    alias vimdnsmasq='vim "$cdetc/dnsmasq.conf" -c "lcd \$cdetc"'
    alias vimdnscrypt='vim "$cdetc/dnscrypt-proxy.conf" -c "lcd \$cdetc"'
    alias vimgitexclude='vim "$(git rev-parse --show-toplevel)/.git/info/exclude"'
    alias vimgitsparsecheckout='vim "$(git rev-parse --show-toplevel)/.git/info/sparse-checkout"'
    alias vimbashhistory='vim ~/.bash_history'
    alias vimbadhosts='vim "$cdetc/badhosts" -c "lcd \$cdetc"'
    alias vimiptables='vim "$cdetc/iptables.sh" -c "lcd \$cdetc"'
    alias vimipset='vim "$cdetc/ipset.conf" -c "lcd \$cdetc"'
    alias vimleinprofiles='vim "$cdhaus/etc/_lein/profiles.clj" -c "lcd \$cdhaus"'
    alias vimleinsampleproject='vim "$cdsrc/leiningen/sample.project.clj"'
    alias vimmappings='vim "$cdhaus/etc/vim/local/mappings.vim" -c "lcd \$cdhaus"'
    alias vimmuttrc='vim "$cdhaus/etc/_mutt/muttrc" -c "lcd \$cdhaus"'
    alias vimnginx='vim "$cdnginx/nginx.conf" -c "lcd \$cdnginx"'
    alias vimorg='vim -c Org!'
    alias vimpacman='vim "$cdetc/pacman.conf" -c "lcd \$cdetc"'
    alias vimgunsrepl='vim "$cdgunsrepl/src/guns/repl.clj" -c "lcd \$cdgunsrepl"'
    alias vimhausrakefile='vim "$cdhaus/Rakefile" -c "lcd \$cdhaus"'
    alias vimscratch='vim -c Scratch'
    alias vimsshconfig='vim "$cdetc/ssh/ssh_config" -c "lcd \$cdetc"'
    alias vimtodo='vim -c "Org! TODO"'
    alias vimtmux='vim "$cdhaus/etc/tmux.conf" -c "lcd \$cdhaus"'
    alias vimunicode='vim "$cdhaus/share/doc/unicode-table.txt.gz" -c "lcd \$cdhaus"'
    alias vimrc='vim "$cdhaus/etc/vimrc" -c "lcd \$cdhaus"'
    alias vimwm='vim "$cdhaus/etc/_config/bspwm/bspwmrc" -c "lcd \$cdhaus"'
    alias vimwmkeybindings='vim "$cdhaus/etc/_config/sxhkd/sxhkdrc" -c "lcd \$cdhaus"'
    alias vimxinitrc='vim "$cdhaus/etc/xinitrc" -c "lcd \$cdhaus"'
    alias vimxdefaults='vim "$cdhaus/etc/Xdefaults" -c "lcd \$cdhaus"'
}

### Terminal Multiplexers

# Tmux
ALIAS tm='tmux' && {
    HAVE tmuxlaunch && alias xtmuxlaunch='exec tmuxlaunch'

    tmuxeval() {
        local vars=$(sed "s:^:export :g" <(tmux show-environment | grep --extended-regexp "^[A-Z_]+=[a-zA-Z0-9/.-]+$"))
        echo "$vars"
        eval "$vars"
    }
}

envtmux() {
    run env $([[ "$TERM" == tmux* ]] && echo TERM=screen-256color) "$@"
}; TCOMP exec envtmux

# GNU screen
HAVE screen && {
    alias screenr='screen -R'
    alias xscreenr='exec screen -R'; TCOMP screen xscreenr
}

### Compilers

# gcc
ALIAS gccas='gcc -S -masm=intel'

# make
ALIAS mk='make' \
      mkinstall='make install' \
      mkj='make --jobs=$(grep --count ^processor /proc/cpuinfo)' \
      mke='make --environment-overrides' \
      mkej='mkj --environment-overrides' \
      mkb='make --always-make' \
      mkbj='mkj --always-make'

# golang
HAVE go && {
    goget()           { run go get -u -v "$@"; }
    gobuild()         { run go build -i -v "$@"; }
    goassemble()      { go build -v -gcflags=-S "$@" 2>&1 | ruby -e 'puts $stdin.read.gsub(%r{\(#{Regexp.escape Dir.pwd}/}, %q{(})'; }
    gooptimizations() { run go build -v -gcflags='-m -d=ssa/check_bce' "$@"; }
    goinstall()       { run go install -v "$@"; }
    gotest()          { run go test -tags test -run="${1:-.}" "${@:2}"; }
    gorace()          { run go test -tags test -race -run="${1:-.}" "${@:2}"; }
    gobench()         { run go test -bench="${1:-.}" -benchmem "${@:2}"; }
    gogenerate()      { run go generate "$@"; }
    golistfiles()     { run go list -f "{{.GoFiles}}" -tags "$1" "${@:2}"; }
    golistimports()   { run go list -f '{{.Imports}}' -tags "$1" "${@:2}"; }
    godocserver()     { run godoc -http="127.0.0.1:$((0xD0C))"; }
    gopprof()         { run env PPROF_BINARY_PATH="$PATH" PPROF_TMPDIR='.' rlwrap go tool pprof "$@"; }

    HAVE gb && {
        alias gbb='run gb build'
        alias gbv='run gb vendor'
        alias gbvf='run gb vendor fetch'
        alias gbvu='run gb vendor update -all'
    }
}

### Debuggers

ALIAS gdbrun='gdb -ex=run --args'

### SCM

# diff patch
ALIAS di='diff --unified=3' \
      diw='di --ignore-all-space' \
      dir='di --recursive' \
      diq='di --brief' \
      dirq='dir --brief'
HAVE dwdiff && dwd() { ruby -e 'exec *($stdin.tty? ? %w[dwdiff --color] : %w[dwdiff --diff-input --color])'; }
ALIAS patch='patch --version-control never'

# git
HAVE git && {
    alias gitgc='run git gc --aggressive --prune=all'

    # Github
    # Param: $1   User name
    # Param: $2   Repository name
    # Param: [$3] Branch name
    githubclone() {
        (($# == 1 || $# == 2)) || { echo "Usage: $FUNCNAME user/repo [branch]"; return 1; }
        local user="${1%%/*}" repo="${1#*/}" branch
        [[ $2 ]] && branch="--branch $2"
        run git clone $branch "https://github.com/${user}/${repo}.git"
    }

    # PS1 git status
    REQUIRE ~/.bashrc.d/git-prompt.sh
    gitps1() {
        __ps1toggle__ '/\\w/\\w\$(__git_ps1 \" → \\[\\033[3m\\]%s\\[\\033[23m\\]\")'
    }; gitps1
}
githubget() {
    (($# == 1 || $# == 2)) || { echo "Usage: $FUNCNAME user/repo [branch]"; return 1; }
    local user="${1%%/*}" repo="${1#*/}" branch="${2:-master}"
    curl --progress-bar --location "https://github.com/$user/$repo/tarball/$branch"
}

### Time

type -P time &>/dev/null && {
    T() { command time -f "\nCPU: %e (%S/%U/%P)\nMEM: %t kB avg, %M max kB\nIO:  %I fsin, %O fsout, %r sockin, %s sockout, %k signals, %x exit" "$@"; }
    TCOMP exec T
}

DATE()     { date '+%Y-%m-%d'; }
TIME()     { date '+%H·%M·%S'; }
DATETIME() { date '+%Y-%m-%d.%H·%M·%S'; }

### Ruby

type ruby &>/dev/null && {
    # Ruby versions
    # Param: $1 Alias suffix
    # Param: $2 Ruby bin directory
    RUBY_VERSION_SETUP() {
        local suf="$1" bin="$2"
        ALIAS "ruby${suf}=${bin}/ruby" && {
            alias "rb${suf}=${bin}/ruby"
            eval "rb${suf}e() { ${bin}/ruby -e 'eval ARGV.join(%q( ))' -- \"\$@\"; }"

            CD_FUNC -e "cdruby${suf}" "ruby${suf} -r mkmf -e \"puts RbConfig::CONFIG['rubylibdir']\""
            CD_FUNC -e "cdgems${suf}" "ruby${suf} -rubygems -e \"puts ([Gem.user_dir, Gem.dir].find { |d| File.directory? d } + '/gems')\""

            # Rubygems package manager
            ALIAS "gem${suf}=${bin}/gem" && {
                # alias geme
                alias "gem${suf}i=${bin}/gem install"
                alias "gem${suf}r=${bin}/gem uninstall"
                alias "gem${suf}s=${bin}/gem search --remote"
                alias "gem${suf}g=${bin}/gem list | g"
                alias "gem${suf}q=${bin}/gem specification --remote"
                # alias gemsync
                alias "gem${suf}upgrade=${bin}/gem update"
                alias "gem${suf}outdated=${bin}/gem outdated"
            }

            # IRB
            if [[ "$suf" == 18* ]]; then
                ALIAS "irb${suf}=${bin}/irb -Ku"
                ALIAS "irb${suf}m=${bin}/irb -Ku -m"
            else
                ALIAS "irb${suf}=${bin}/irb"
                ALIAS "irb${suf}m=${bin}/irb -m"
            fi

            # Rake
            ALIAS "rake${suf}=${bin}/rake" \
                  "rk${suf}=rake${suf}" \
                  "rk${suf}t=rake${suf} --tasks"

            # Useful gem executables
            ALIAS "b${suf}=${bin}/bundle" \
                  "bx${suf}=${bin}/bundle exec" \
                  "brk${suf}=${bin}/bundle exec rake" \
                  "brk${suf}t=${bin}/bundle exec rake --tasks" \
                  "binstall${suf}=${bin}/bundle install"
        }
    }; GC_FUNC RUBY_VERSION_SETUP

    # Set top Ruby to be the first extant dir in RUBYPATH
    if [[ -d "${RUBYPATH%%:*}" ]]; then
        RUBY_VERSION_SETUP '' "${RUBYPATH%%:*}"
    else
        RUBY_VERSION_SETUP '' "$(dirname "$(type -P ruby)")"
    fi
    RUBY_VERSION_SETUP 20  /opt/ruby/2.0/bin
    RUBY_VERSION_SETUP 19  /opt/ruby/1.9/bin
    RUBY_VERSION_SETUP 18  /opt/ruby/1.8/bin
    RUBY_VERSION_SETUP 186 /opt/ruby/1.8.6/bin

    # RUBYOPT
    rbopt() { run env RUBYOPT="$1" "${@:2}"; }

    # PATH variables
    rubylib() { __prepend_path__ RUBYLIB "$@"; }
    gempath() { path "${@:-.}/bin"; rubylib "${@:-.}/lib"; }

    # Rails
    rails() {
        if [[ -x script/rails ]]; then
            run script/rails "$@"
        else
            run rails "$@"
        fi
    }

    # R(ACK|AILS)_ENV
    rackenv() {
        (($#)) && export RAILS_ENV="$1" RACK_ENV="$1"
        echo "RAILS_ENV=${RAILS_ENV} RACK_ENV=${RACK_ENV}"
    }; complete -F __rackenv__ rackenv

    rklink() {
        case $# in
        0) local fname="${PWD##*/}";;
        1) local fname="$1";;
        *) echo "USAGE: $FUNCNAME [srcname]"; return 1;;
        esac

        local src="$cdhaus/share/rake/$fname"
        if [[ -e "$src" ]]; then
            ln --symbolic "$src" Rakefile
        else
            echo "$src does not exist!"
            return 1
        fi
    }
}

### Python

ALIAS py='python' \
      py2='python2'

### JVM

# Leiningen
HAVE lein && {
    # alias leine=
    # alias leing=
    alias leini='run lein install'
    # alias leinq=
    alias leins='run lein search'
    # alias leinu=
    # alias leinsync=
    alias leinoutdated='lein ancient :all :check-clojure :allow-qualified :allow-snapshots'
}

### Perl

ALIAS perlpe='perl -pe' \
      perlne='perl -ne' \
      perlpie='perl -i -pe'

### Databases

HAVE psql && {
    ALIAS aspostgres='sudo --set-home --login --user postgres'
}

### Hardware control

ALIAS mp='modprobe --all'
ALIAS trim='fstrim --all --verbose'

ALIAS rfk='rfkill' && {
    alias rfdisable='run rfkill block all'
    alias rfenable='run rfkill unblock all'
}

HAVE lsblk && {
    lsb() {
        if (($#)); then
            lsblk --all "$@"
        else
            lsblk --all --output NAME,SIZE,RM,RO,TYPE,FSTYPE,LABEL,MOUNTPOINT
        fi
    }
    alias lsbfs='lsb --fs'
    alias lsbmode='lsb --perms'
    alias lsbscsi='lsb --scsi'
}

HAVE hdparm && {
    hdpowerstatus() {
        local disks=($(lsdisk))
        hdparm -C "${disks[@]}"
    }
    alias hdstandby='hdparm -y'; complete -F __lsdisk__ hdstandby
    alias hdsleep='hdparm -Y'; complete -F __lsdisk__ hdsleep
}

HAVE wpa_supplicant wpa_passphrase && {
    wpajoin() {
        local OPTIND OPTARG opt iface='wlan0'
        while getopts :i: opt; do
            case $opt in
            i) iface="$OPTARG";;
            *) echo "USAGE: $FUNCNAME [-i iface] essid [password]"; return 1
            esac
        done
        shift $((OPTIND-1))
        local ssid="$1"; [[ $ssid ]] || ssid=$(printf "ssid: " >&2; read r; echo "$r")
        local pass="$2"; [[ $pass ]] || pass=$(printf "pass: " >&2; read r; echo "$r")
        run wpa_supplicant -i "$iface" -c <(wpa_passphrase "$ssid" "$pass")
    }
}

### Encryption

# OpenSSL
ALIAS ssl='openssl' && {
    aesencrypt() { if (($#)); then openssl aes-256-cbc    -in "$@"; else openssl aes-256-cbc;    fi; }
    aesdecrypt() { if (($#)); then openssl aes-256-cbc -d -in "$@"; else openssl aes-256-cbc -d; fi; }
}

# GnuPG
# HACK: This allows us to define a default encrypt-to in gpg.conf for
#       applications like mutt
if ALIAS gpg='gpg2 --no-encrypt-to' || ALIAS gpg='gpg --no-encrypt-to'; then
    ALIAS gpgverify='gpg --verify-files'
    gpgsign() {
        local f
        for f in "$@"; do
            gpg --detach-sign "$f"
        done
    }
    alias gpgkilldaemons='run gpgconf --kill $(gpgconf --list-components gpgconf | cut -d: -f1)'
fi

# pass
HAVE pass && {
    TCOMP pass passclip
    passl() { pass "$@" | pager; }; TCOMP pass passl
    passnew() { pass insert --force --multiline "$1" < <(genpw "${@:2}") &>/dev/null; pass "$1"; }; TCOMP pass passnew
    passnewclip() { passnew "$@" | clip; }; TCOMP pass passnewclip
}

# cryptsetup
ALIAS cs='cryptsetup' && {
    TCOMP umount csumount
    alias csdump='cryptsetup luksDump'; complete -F __partitions__ csdump
    alias cssuspend='cryptsetup luksSuspend'; complete -F __cryptnames__ cssuspend
    alias csresume='cryptsetup luksResume'; complete -F __cryptnames__ csresume
}

HAVE cert && {
    # Duplicated in bin/cert
    cx() {(
        local certfile="/etc/ca-certificates/trust-source/anchors/$1"
        local keystore="/etc/ca-certificates/trust-source/anchors/${1%.crt}.ks"

        export CURL_CA_BUNDLE="$certfile" # curl
        export GIT_SSL_CAINFO="$certfile" # git
        export SSL_CERT_FILE="$certfile" # ruby

        # Leiningen
        if [[ -e "$keystore" ]]; then
            export JVM_OPTS="$JVM_OPTS -Djavax.net.ssl.trustStore=${keystore}"
            export LEIN_JVM_OPTS="$LEIN_JVM_OPTS -Djavax.net.ssl.trustStore=${keystore}"
        fi

        # Eval to pick up aliases
        eval "${@:2}"
    )}; complete -F __cx__ cx
}

HAVE keytool && java-import-keystore() {
    (($# == 2)) || { echo "USAGE: $FUNCNAME crtfile keystore"; return 1; }
    run keytool -storepass changeit -importcert -file "$1" -keystore "$2"
}

### Package Managers

# Aptitude
HAVE apt && {
    alias apti='run apt install'
    alias aptr='run apt remove'
    alias apts='run apt search'
    alias aptg='run dpkg --list | g'
    aptq() {
        local pkg
        for pkg in "$@"; do
            apt show "$pkg"
            dpkg --listfiles "$pkg"
        done
    }
    alias aptsync='run apt update'
    alias aptupgrade='run apt update; run apt full-upgrade'
    alias aptoutdated='run apt list --upgradable'
    alias aptclean='run apt-get autoclean; run apt-get --yes autoremove'
    # alias aptforeign=
    alias aptlog='pager /var/log/apt/history.log'
    alias aptowner='run dpkg --search'
}

# Pacman
ALIAS pac='pacman' && {
    alias paci='run pacman --sync --needed'
    alias pacr='run pacman --remove --recursive'
    alias pacs='run pacman --sync --search'
    alias pacg='run pacman --query --search'
    pacq() {
        local pkg
        for pkg in "$@"; do
            if pacman --query --info "$pkg"; then
                pactree --reverse "$pkg"; echo
                pacman --query --list "$pkg"; echo
            else
                pacman --sync --info "$pkg"
            fi
        done 2>/dev/null | pager
    }
    alias pacsync='run pacman --sync --refresh'
    alias pacupgrade='run pacman --sync --refresh --sysupgrade'
    alias pacoutdated='run pacman --query --upgrades; run pacckalts; type pacaur &>/dev/null && run pacaur --check $(pacforeign)'
    alias pacclean='run pacman --sync --clean --noconfirm'
    pacforeign() {
        ruby -e '
            puts %x(pacman --query --foreign --info).split("\n\n").reduce([]) { |pkgs, pkg|
                (pkg[/Groups\s*:\s*(.*)/, 1].split & %w[nerv nerv-alt]).empty? \
                    ? pkgs << pkg[/Name\s*:\s*(.*)/, 1] \
                    : pkgs
            }
        '
    }
    alias pacorphans='run pacman --query --deps --unrequired'
    alias paclog='pager /var/log/pacman.log'
    alias pacowner='run pacman --query --owns'

    ALIAS packey='pacman-key'

    ALIAS mkp='makepkg' \
          mkpf='makepkg --force' \
          mkpc='makepkg --cleanbuild --force' \
          mkps='makepkg --syncdeps' \
          mkpa='makepkg --ignorearch' \
          mkpo='makepkg --nobuild'

    pkgbuild() {
        run cp --no-clobber --verbose /usr/share/pacman/PKGBUILD.proto "${1:-.}/PKGBUILD"
    }

    pacfindunknown() {
        find "$@" -exec pacman --query --owns -- {} + 2>&1 >/dev/null
    }; TCOMP find pacfindunknown

    _xspecs['pacinstallfile']='!*.pkg.tar.xz'
    complete -F _filedir_xspec pacinstallfile

    pacdowngrade() {
        local OPTIND OPTARG opt sign=0

        while getopts :s opt; do
            case $opt in
            s) sign=1;;
            esac
        done
        shift $((OPTIND-1))

        if ((sign)); then
            (cd /var/cache/pacman/pkg
            for f in "$@"; do
                [[ -e "$f.sig" ]] || run gpg --detach-sign "$f"
            done)
        fi
        run pacman --upgrade "${@/#//var/cache/pacman/pkg/}";
    }
    complete -F __pacdowngrade__ pacdowngrade

    aurclone() {
        local name
        for name in "$@"; do
            run git clone "https://aur.archlinux.org/${name}.git"
        done
    }

    HAVE pacaur && {
        alias aur="AURDEST=\"$cdarchlinux/aur\" pacaur"; TCOMP pacaur aur
        # alias auri
        alias aurs='aur --search'
        # alias aurg
        alias aurq='aur --info'
        alias auroutdated='aur --check'
    }
}

# dnf
HAVE dnf && {
    alias dnfi='run dnf install'
    alias dnfr='run dnf remove'
    alias dnfs='run dnf search'
    alias dnfg='rpm --query --all | g'
    dnfq() {
        local pkg
        for pkg in "$@"; do
            dnf info "$pkg" && dnf repoquery -l "$pkg"
        done 2>/dev/null | pager
    }
    # dnfsync
    alias dnfupgrade='run dnf upgrade'
    alias dnfoutdated='run dnf check-update'
    alias dnfclean='run dnf clean all'
}

### Media

# Imagemagick
ALIAS geometry='identify -format "%wx%h"'

# feh
HAVE feh && {
    ALIAS fshow='feh --sort=dirname --recursive' \
          frand='feh --sort=dirname --recursive --randomize' \
          ftime='feh --sort mtime'
    alias fmove='fehmove'
    alias fcopy='fehmove --copy'
}

# cmus
HAVE cmus && alias cmus='envtmux cmus'

# pulseaudio
HAVE pulseaudio && {
    alias pastart='run pulseaudio --start'
    alias pastop='run pulseaudio --kill'
    alias parestart='run pulseaudio --kill; run pulseaudio --start'
}

# youtube-dl
HAVE youtube-dl && {
    TCOMP youtube-dl yt
    TCOMP youtube-dl ytv
}

### X

HAVE startx && alias xstartx='exec startx &>/dev/null'

# GTK
HAVE gtk-update-icon-cache && gtk-update-icon-cache-all() {
    local dir
    for dir in ~/.icons/*; do
        [[ -d "$dir" ]] && run gtk-update-icon-cache --force --ignore-theme-index "$dir"
    done
}

# slop
ALIAS xgeom='slop'

### TTY

ALIAS rl='rlwrap' && TCOMP exec rl

### Init

if HAVE systemctl; then
    ALIAS sc='systemctl' \
          scu='systemctl --user' \
          jc='journalctl' \
          jcu='journalctl --user' \
          jcb='journalctl --boot' \
          jce='journalctl --pager-end' \
          jcf='journalctl --follow' \
          jcverify='journalctl --verify' \
          mc='machinectl'
    alias sctimers='systemctl list-timers'
    alias scunitfiles='systemctl list-unit-files'
    alias scrunning='systemctl list-units --state=running'
    alias scdaemonreload='systemctl --system daemon-reload'
    alias scedit='systemctl edit --full'; complete -F __systemd_units__ scedit
    alias scdelta='systemd-delta'
else
    RC_FUNC rcd /etc/{rc,init}.d /usr/local/etc/{rc,init}.d
fi

### GUI programs

ALIAS kf='kupfer' && {
    alias kfrestart='pkill --exact kupfer; (cddownloads && bgrun kupfer --no-splash)'
}

: # Return true
