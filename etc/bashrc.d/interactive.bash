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

    local newpath=$(ruby -e '
        paths = (ENV[ARGV[0]] || "").split ":"
        ARGV.drop(1).reverse_each do |dir|
            dir = File.expand_path dir
            next unless File.directory? dir
            paths.reject! { |d| d == dir }
            paths.unshift dir
        end
        puts paths.join(":")
    ' "$var" "${@:2}")

    export "$var=$newpath"
    echo "$var=$newpath"
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

__lsdisk__() {
    __compreply__ "$(lsdisk)"
}

__partitions__() {
    __compreply__ "$(awk 'NR > 2 {print "/dev/"$NF}' /proc/partitions)"
}

__pacdowngrade__() {
    __compreply__ "$(command ls -1 /var/cache/pacman/pkg/ | grep -E 'pkg\.tar\.[a-z]+$')"
}

__pacman_sync__() {
    type _pacman_pkg &>/dev/null || __load_completion pacman

    local common core cur database files prev query remove sync upgrade o
    COMPREPLY=()
    _get_comp_words_by_ref cur prev

    _pacman_pkg Slq
}

__pacman_pkgs__() {
    type _pacman_pkg &>/dev/null || __load_completion pacman

    local common core cur database files prev query remove sync upgrade o
    COMPREPLY=()
    _get_comp_words_by_ref cur prev

    _pacman_pkg Qq
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
CD_FUNC cdanchors       /etc/ca-certificates/trust-source/anchors
CD_FUNC cddnscrypt      /etc/dnscrypt-proxy
CD_FUNC -x cdnginx      /etc/nginx
CD_FUNC -n cdusb        /mnt/usb
CD_FUNC cdtmp           ~/tmp "$TMPDIR" /tmp
CD_FUNC cdm             /var/lib/machines
CD_FUNC cdpostgres      /var/lib/postgres
CD_FUNC cdlog           /var/log
CD_FUNC cdpacmancache   /var/cache/pacman/pkg
CD_FUNC cdwww           /srv/http /srv/www /var/www
CD_FUNC -x cdapi        "$cdwww/api.test"
CD_FUNC cdconfig        ~/.config
CD_FUNC cdlocal         ~/.local /usr/local
CD_FUNC cdLOCAL         /usr/local
CD_FUNC cdgo            "${GOPATH%%:*}" /opt/src/go
CD_FUNC cdpass          ~/.password-store
CD_FUNC -x cdsrc        /opt/src ~/src /usr/local/src
CD_FUNC cdSRC           "$cdsrc/READONLY"
CD_FUNC cdarchlinux     "$cdsrc/archlinux"
CD_FUNC cdvimfiles      "$cdsrc/vimfiles"
CD_FUNC cddesktop       ~/Desktop ~guns/Desktop
CD_FUNC cddocuments     ~/Documents ~guns/Documents
CD_FUNC cddownloads     ~/Downloads ~guns/Downloads
CD_FUNC cddbeaver       ~/.local/share/DBeaverData/workspace6/General/Scripts

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

alias h='history'
alias j='jobs'
alias o='echo'
alias t='type --'; TCOMP type t
alias ta='type -a --'; TCOMP type ta
alias tp='type -P --'; TCOMP type tp
alias x='exec'; TCOMP exec x
alias us='unset'; TCOMP unset us
alias xp='export'; TCOMP export xp
alias wrld='while read l; do'; TCOMP exec wrld
alias comp='complete -p'; TCOMP complete comp

# PATH manipulation
alias path='__prepend_path__ PATH'
alias ldpath='__prepend_path__ LD_LIBRARY_PATH'
alias gopath='__prepend_path__ GOPATH'
alias rubylib='__prepend_path__ RUBYLIB'

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
        HISTFILE="${HISTFILE_DISABLED:-$HOME/.cache/bash_history}"
        unset HISTFILE_DISABLED
    fi
    __ps1toggle__ '/\\H/[nohist] \\H'
}
if ((NOHIST == 1)); then nohist; fi

# Repeat
rep() {
    for ((i = 0; i < "$1"; ++i)); do
        { eval "${@:2}"; } || break
    done
}

# notify
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

# run bgrun
TCOMP exec run
TCOMP exec bgrun

### Files, Disks, and Memory

# grep
alias g="grep --ignore-case --color --perl-regexp"
alias gw='g --word-regexp'
alias gv='g --invert-match'
alias gc='grep --count .'

# ripgrep
alias rgi='rg --ignore-case'
alias rgf='rg --fixed-strings'
alias rgu='rg -uuu'
alias rgiu='rg --ignore-case -uuu'

# cat tail less
alias c='cat'
alias tf='tail --follow=name --retry'
alias l='less'
alias L='less -+S'
alias lf='less +F'

# ls
alias ls="ls -l --almost-all --human-readable --quoting-style=literal --show-control-chars --color"
alias lc="command ls -C --color"
alias lsg='ls | g'
alias lsd='ls --directory'
lsr() { ls --recursive "${@:-.}" | pager; }
lst() { ls -t "${@:-.}" | pager; }
alias l1='command ls -1'
alias lsmapper='ls /dev/mapper'
for d in /dev/disk/by-*; do
    alias lsby"${d:13}"="ls $d"
done; unset d
lsdbus() { find /usr/share/dbus-1 -name "*.service" | sort; }
ls.() { __lstype__ "${1:-.}" 'f =~ /\A\./'; }
lsf() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "file"'; }
lsl() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "link"'; }
lsx() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "file" and File.executable? f'; }
lsD() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "directory"'; }

# objdump hexdump strings readelf hexfiend
hex() { hexdump --canonical "$@" | pager; }; TCOMP hexdump hex
ox() { objdump --all-headers "$@" | pager; }; TCOMP objdump ox
disas() { objdump -D -M intel-mnemonic "$@" | pager; }
dylibs() { readelf --dynamic "$@" | pager; }; TCOMP readelf dylibs
strings() { command strings --all --radix=x "$@" | pager; }

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
    find-wrapper --predicate '( -type f -o -type l ) -print0' -- "$@" | ruby -e '
        puts $stdin.read.split("\0").sort_by { |f| -File.mtime(f).to_i }
    '
}; TCOMP find fft
fft0() {
    find-wrapper --predicate '( -type f -o -type l ) -print0' -- "$@" | ruby -e '
        puts $stdin.read.split("\0").sort_by { |f| -File.mtime(f).to_i }.join("\0")
    '
}; TCOMP find fft0

# Breadth-first search and chdir
cdf() { cd "$(if ! find-directory "$@"; then echo .; fi)"; }

# cd physical path
cdp() { cd "$(pwd -P)"; }

# cd git root
cdroot() { cd "$(git rev-parse --show-toplevel)"; }

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
alias chownr='chown --recursive'; TCOMP chown chownr

# mkdir
alias md='mkdir --verbose --parents'; complete -o dirnames md
alias rd='rmdir --verbose --parents'; complete -o dirnames rd
mdf() { mkdir --verbose --parents "$@"; cd "$1"; }; complete -o dirnames mdf

# df du
alias df='df --human-readable'
alias du='du --human-readable'
alias dus='du --summarize'

# mount
mt() {
    if (($#)); then
        run mount --verbose --options noatime "$@"
    elif type findmnt &>/dev/null; then
        findmnt
    else
        mount
    fi
}; TCOMP mount mt
alias mtb='mt --bind'; TCOMP mount mtb
alias mtro='mt --read-only'; TCOMP mount mtro
alias mtbro='mt --bind --read-only'; TCOMP mount mtbro
alias umt='umount --verbose'; TCOMP mount umt
alias mtusb='mountusb'; complete -F __mtusb__ mtusb
alias umtusb='umountusb'
remt() {
    if (($# < 2)); then
        echo "USAGE: $FUNCNAME mount-opts mountpoint"
        return 1
    else
        run mount --verbose --options "remount,$1" "${@:2}"
    fi
}; TCOMP umount remt
mtlabel() {
    (($# >= 2)) || { echo "$FUNCNAME label mount-args" >&2; return 1; }
    run mount --options noatime "/dev/disk/by-label/$1" "${@:2}"
}; complete -F __mtlabel__ mtlabel

# findmnt
alias fm='findmnt'

# lsblk
lsb() {
    if (($#)); then
        lsblk --all "$@"
    else
        lsblk --all --output NAME,SIZE,RM,RO,TYPE,FSTYPE,LABEL,MOUNTPOINT
    fi
}; TCOMP lsblk lsb
alias lsbfs='lsb --fs'
alias lsbmode='lsb --perms'
alias lsbscsi='lsb --scsi'

# tar
alias lstar='tar --list --verbose --file'
untar() {
    local opts=() file
    [[ "$1" == --strip-components=* ]] && { opts+=("$1"); shift; }
    [[ -f "$1" ]] && file='--file';
    run tar --extract --verbose $file "$@" "${opts[@]}"
}
alias star='tar --strip-components=1'
alias gtar='tar --gzip --create --verbose'
alias btar='tar --bzip2 --create --verbose'
alias xtar='tar --xz --create --verbose'
alias ztar='tar --zstd --create --verbose'
alias suntar='untar --strip-components=1'
alias guntar='untar --gunzip'
alias buntar='untar --bzip2'
alias xuntar='untar --xz'
alias zuntar='untar --zstd'

# open
alias op='open 2>/dev/null'; complete -F _minimal op

# rsync
alias rsync='rsync -hhh --sparse --partial'; TCOMP rsync rsync-backup

# dd
HAVE dcfldd && { alias dd='dcfldd'; TCOMP dd dcfldd; }
TCOMP dd ddsize

# free
alias free='free --human'

# iotop
alias iotop='iotop --only'

# Swap
alias swapin='swapoff --all --verbose; swapon --all --verbose'

# attributes
alias lsa='lsattr -a'
alias chimmutable='chattr -V +i'
alias chmutable='chattr -V -i'

# inotifywait
HAVE inotifywait && fwatch() {
    local OPTIND OPTARG opt recurse
    while getopts :hr opt; do
        case "$opt" in
        h) echo "USAGE: $FUNCNAME [-r] file … -- cmd …" >&2; return;;
        r) recurse=1;;
        esac
    done
    shift $((OPTIND-1))

    local args=("$@") files=() cmd=()
    for ((i = 0; i < $#; ++i)); do
        if [[ "${args[i]}" == '--' ]]; then
            cmd+=(${args[@]:i+1})
            break
        else
            files+=(${args[i]})
        fi
    done

    if ((${#files[@]} == 0)); then
        echo "No files to watch!" >&2
        return 1
    elif ((${#cmd[@]} == 0)); then
        echo "No commands given!" >&2
        return 1
    fi

    while :; do
        until stat "${files[@]}" &>/dev/null; do
            sleep 1
        done

        local f=$(ruby -r fileutils -r shellwords -e '
            cmd = %w[inotifywait --monitor --event close_write --event attrib --quiet --format %w%f]
            cmd << "--recursive" if ARGV[0] == "1"
            cmd.concat ARGV.drop(1)

            warn cmd.shelljoin

            IO.popen cmd do |io|
                Thread.new { $stdin.gets; Process.kill :TERM, io.pid }
                io.each_line do |line|
                    line.chomp!
                    if File.file? line
                        puts line
                        Process.kill :TERM, io.pid
                        Process.wait io.pid
                        exit
                    end
                end
            end
        ' -- "$recurse" "${files[@]}")

        eval "${cmd[@]}"
        sleep 0.5
    done
}

# Check shell init files and system paths for loose permissions
ckperm() { source "$cdhaus/bin/checkpermissions.bash"; }

### Processes

# kill
alias k='kill'; TCOMP kill k
alias k9='kill -KILL'
alias khup='kill -HUP'
alias kint='kill -INT'
alias kstop='kill -STOP'
alias kcont='kill -CONT'
alias kusr1='kill -USR1'
alias kquit='kill -QUIT'
alias kabort='kill -ABRT'
alias ka='killall --exact --verbose'; TCOMP killall ka
alias ka9='ka -KILL'
alias kahup='ka -HUP'
alias kaint='ka -INT'
alias kastop='ka -STOP'
alias kacont='ka -CONT'
alias kausr1='ka -USR1'
alias kaquit='ka -QUIT'
alias kaabort='ka -ABRT'
alias pk='pkill --exact'; TCOMP pkill pk
alias pk9='pk -KILL'
alias pkhup='pk -HUP'
alias pkint='pk -INT'
alias pkstop='pk -STOP'
alias pkcont='pk -CONT'
alias pkusr1='pk -USR1'
alias pkquit='pk -QUIT'
alias pkabort='pk -ABRT'

# ps (traditional BSD / SysV flags seem to be the most portable)
alias psa='ps axo comm,pid,ppid,pgid,sid,nlwp,pcpu,pmem,rss,start_time,user,tt,ni,pri,stat,args'
alias psg='pgrep -a'
if [[ "$MACHTYPE" == *-linux-* ]]; then
    # GNU ps supports `k` and `--sort`
    psr() { psa k-pcpu "$@" | pager; }
    psm() { psa k-rss  "$@" | pager; }
else
    # BSD ps supports `-r` and `-m`
    psr() { psa -r "$@" | pager; }
    psm() { psa -m "$@" | pager; }
fi

# pstree
alias pst='pstree'

# htop/nmon
alias nmon='NMON=dln- nmon'

### Documentation

alias info='info --vi-keys'

### Switch User

alias s='sudo --set-home'; TCOMP sudo s
alias xsu='exec su'; TCOMP su xsu

### Network

# ip
alias a='ip addr'
alias 4='ip -4'
alias 6='ip -6'

# ifconfig
alias ic='ifconfig'

# netctl
HAVE netctl && {
    net() {
        if (($#)); then
            netctl "$@"
        else
            netctl list
        fi
    }; TCOMP netctl net
}

# cURL/wget
TCOMP curl get
TCOMP wget dl

# netcat
HAVE ncat && {
    complete -p ncat &>/dev/null || complete -F _known_hosts ncat
}

# ssh scp
alias ssh-password='ssh -o "PreferredAuthentications password"'; TCOMP ssh ssh-password
alias ssh-remove-host='ssh-keygen -R'; complete -F _known_hosts ssh-remove-host
alias ssh-pubkey='ssh-keygen -y -f'
alias scpr='scp -r'; TCOMP scp scpr

# lsof
alias lsof='lsof +c0 -Pwn +fg'
alias lsif='lsof -i'
alias lsifr='command lsof +c0 -Pwi +fg'
alias lsifudp='lsif | grep UDP'
alias lsiflisten='lsif | grep --word-regexp "LISTEN\|UDP"'
alias lsifconnect='lsif | grep -- "->"'
alias lsifconnectr='lsifr | grep -- "->"'
alias lsuf='lsof -U'

# ngrep
alias ngg='ngrep -c 0 -d any -l -q -P "" -W byline'

# Weechat
if ((EUID > 0)) && HAVE weechat; then
    alias irc='(cd ~/.weechat && exec weechat)'
fi

# dnscrypt-proxy
alias dnscrypt='dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml'

### Firewalls

# iptables
alias iptables.script='/etc/iptables.script'
alias iptw='ipt --wait'; complete -F _longopt iptw
complete -F _longopt ipt

### Editors

# Vim
HAVE vim && {
    alias v='vim -c "set nomodified" -'

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
            vim -c 'FZF!'
        fi
    }; TCOMP find vimfind

    # Vim-ManPage
    alias mman='command man'; TCOMP man mman
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

    # XtermColorTable
    alias xtermcolortable='vim -c OXtermColorTable'

    # VIMEDITBINDINGS
    alias vimautocommands='vim "$cdhaus/etc/vim/local/autocommands.vim" -c "lcd \$cdhaus"'
    alias vimabook='vim ~/.abook/addressbook -c "lcd ~/.abook"'
    alias vimbashinteractive='vim "$cdhaus/etc/bashrc.d/interactive.bash" -c "lcd \$cdhaus"'
    alias vimbashrc='vim "$cdhaus/etc/bashrc" -c "lcd \$cdhaus"'
    alias vimcommands='vim "$cdhaus/etc/vim/local/commands.vim" -c "lcd \$cdhaus"'
    alias vimdnsmasq='vim "/etc/dnsmasq.conf" -c "lcd /etc/"'
    alias vimdnscrypt='vim "/etc/dnscrypt-proxy/dnscrypt-proxy.toml" -c "lcd /etc/"'
    alias vimfstab='vim /etc/fstab'
    alias vimgitexclude='vim "$(git rev-parse --show-toplevel)/.git/info/exclude"'
    alias vimgitsparsecheckout='vim "$(git rev-parse --show-toplevel)/.git/info/sparse-checkout"'
    alias vimbashhistory='vim ~/.cache/bash_history'
    alias vimhosts='vim "/etc/hosts" -c "lcd /etc/"'
    alias vimiptables='vim "/etc/iptables.script" -c "lcd /etc/"'
    alias vimipset='vim "/etc/ipset.conf" -c "lcd /etc/"'
    alias vimmappings='vim "$cdhaus/etc/vim/local/mappings.vim" -c "lcd \$cdhaus"'
    alias vimmuttrc='vim "$cdhaus/etc/_mutt/muttrc" -c "lcd \$cdhaus"'
    alias vimnginx='vim "$cdnginx/nginx.conf" -c "lcd \$cdnginx"'
    alias vimorg='vim -c Org!'
    alias vimpacman='vim "/etc/pacman.conf" -c "lcd /etc/"'
    alias vimhausrakefile='vim "$cdhaus/Rakefile" -c "lcd \$cdhaus"'
    alias vimscratch='vim -c Scratch'
    alias vimsshconfig='vim "/etc/ssh/ssh_config" -c "lcd /etc/"'
    alias vimtodo='vim -c "Org! TODO"'
    alias vimtmux='vim "$cdhaus/etc/tmux.conf" -c "lcd \$cdhaus"'
    alias vimunicode='vim "$cdhaus/share/doc/unicode-table.txt" -c "lcd \$cdhaus"'
    alias vimrc='vim "$cdhaus/etc/vimrc" -c "lcd \$cdhaus"'
    alias vimwm='vim -O "$cdhaus/etc/_config/sxhkd/sxhkdrc" "$cdhaus/etc/_config/bspwm/bspwmrc" -c "lcd \$cdhaus"'
    alias vimwireguard='vim "/etc/wireguard/wg0.conf" -c "lcd /etc/"'
    alias vimxinitrc='vim "$cdhaus/etc/xinitrc" -c "lcd \$cdhaus"'
    alias vimxdefaults='vim "$cdhaus/etc/Xdefaults" -c "lcd \$cdhaus"'
}

### Terminal Multiplexers

# Tmux
alias xtmuxlaunch='exec tmuxlaunch'
tmuxeval() {
    local vars=$(sed "s:^:export :g" <(tmux show-environment | grep --extended-regexp "^[A-Z_]+=[a-zA-Z0-9/.-]+$"))
    echo "$vars"
    eval "$vars"
}

# GNU screen
HAVE screen && {
    alias screenr='screen -R'
    alias xscreenr='exec screen -R'; TCOMP screen xscreenr
}

### Compilers

# gcc
alias gccas='gcc -S -masm=intel'

# make
alias mk='make'
alias mkinstall='make install'
alias mkj='make --jobs=$(grep --count ^processor /proc/cpuinfo)'
alias mke='make --environment-overrides'
alias mkej='mkj --environment-overrides'
alias mkb='make --always-make'
alias mkbj='mkj --always-make'

# golang
HAVE go && {
    goget()           { run go get -u -v "$@"; }
    gobuild()         { run go build -i -v "$@"; }
    goassemble()      { go build -v -gcflags=-S "$@" 2>&1 | ruby -e 'puts $stdin.read.gsub(%r{\(#{Regexp.escape Dir.pwd}/}, %q{(})'; }
    gooptimizations() { run go build -v -gcflags='-m -d=ssa/check_bce' "$@"; }
    goinstall()       { run go install -v "$@"; }
    gotest()          { run go test -tags test -run="${1:-.}" "${@:2}"; }
    gorace()          { run go test -tags test -race -run="${1:-.}" "${@:2}"; }
    gobenchprof()     { run go test -run=NONE -bench="${1:-.}" -benchmem -cpuprofile=cpu.prof -memprofile=mem.prof "${@:2}"; }
    gogen()           { run go generate -v "$@"; }
    golistfiles()     { run go list -f "{{.GoFiles}}" -tags "$1" "${@:2}"; }
    golistimports()   { run go list -f '{{.Imports}}' -tags "$1" "${@:2}"; }
    godocserver()     { run godoc -http="127.0.0.1:$((0xD0C))"; }
    gopprof()         { run rlwrap go tool pprof -http="127.0.0.1:$((0xD0C))" "$@"; }
}

# rust
HAVE cargo && {
    alias ca='cargo' && TCOMP cargo ca
    alias cabuild='cargo build'
    alias carelease='cargo build --release'
    alias carun='cargo run'
}

### Debuggers

alias gdbrun='gdb -ex=run --args'

### SCM

# diff patch
alias di='diff --unified=3'
alias diw='di --ignore-all-space'
alias dir='di --recursive'
alias diq='di --brief'
alias dirq='dir --brief'
alias dwd="ruby -e 'exec *(\$stdin.tty? ? %w[dwdiff --color] : %w[dwdiff --diff-input --color]) + ARGV'"
alias patch='patch --version-control never'

# git
HAVE git && {
    REQUIRE ~/.bashrc.d/git-prompt.sh
    gitps1() {
        __ps1toggle__ '/\\w/\\w\$(__git_ps1 \" → \\[\\033[3m\\]%s\\[\\033[23m\\]\")'
    }; gitps1
}

### Time

type -P time &>/dev/null && {
    alias T='command time -f "\nCPU: %e (%S/%U/%P)\nMEM: %t kB avg, %M max kB\nIO:  %I fsin, %O fsout, %r sockin, %s sockout, %k signals, %x exit"'
    TCOMP exec T
}

alias DATE="date '+%Y-%m-%d'"
alias TIME="date '+%H:%M:%S'"
alias DATETIME="date '+%Y-%m-%d %H:%M:%S'"

### Ruby

CD_FUNC -e cdruby "ruby -r mkmf -e \"puts RbConfig::CONFIG['rubylibdir']\""
CD_FUNC -e cdgems "ruby -e \"puts ([Gem.user_dir, Gem.dir].find { |d| File.directory? d } + '/gems')\""

# Rake
rk() {
    if [[ -x bin/bundle ]]; then
        run bin/bundle exec rake "$@"
    else
        run rake "$@"
    fi
}; TCOMP rake rk

### JavaScript

# Yarn
alias y='yarn'

### Databases

HAVE psql && {
    alias aspostgres='sudo --set-home --login --user postgres'; TCOMP sudo aspostgres
    alias initpostgres="aspostgres initdb --locale en_US.UTF-8 -E UTF-8 -D \"$cdpostgres/data\""
}

### Containers

HAVE docker && {
    alias d='docker'; TCOMP docker d
    alias dc='docker-compose'; TCOMP docker-compose dc
    alias dcx='docker-compose exec'
}

### Hardware control

alias mp='modprobe --all'; TCOMP modprobe mp
alias trim='fstrim --all --verbose'

HAVE rfkill && {
    alias rfk='rfkill'; TCOMP rfkill rfk
    alias rfdisable='run rfkill block all'
    alias rfenable='run rfkill unblock all'
}

HAVE hdparm && {
    hdpowerstatus() { hdparm -C $(lsdisk); }
    alias hdstandby='hdparm -y'; complete -F __lsdisk__ hdstandby
    alias hdsleep='hdparm -Y'; complete -F __lsdisk__ hdsleep
}

### Encryption

# GnuPG
# HACK: This allows us to define a default encrypt-to in gpg.conf for
#       applications like mutt
alias gpg='gpg --no-encrypt-to'
alias gpgverify='gpg --verify-files'
gpgsign() {
    local f
    for f in "$@"; do
        gpg --detach-sign "$f"
    done
}
alias gpgkilldaemons='run gpgconf --kill all'
alias gpgupdatestartuptty='run gpg-connect-agent updatestartuptty /bye'

# pass
passl() { pass "$@" | pager; }; TCOMP pass passl
passnew() { pass insert --force --multiline "$1" < <(genpw "${@:2}") &>/dev/null; pass "$1"; }; TCOMP pass passnew
passnewclip() { passnew "$@" | clip; }; TCOMP pass passnewclip
TCOMP pass passclip
TCOMP pass passqrshow

# cryptsetup
TCOMP umount csumount
alias csdump='cryptsetup luksDump'; complete -F __partitions__ csdump

### Package Managers

# Rubygems
HAVE gem && {
    alias gemi='run gem install'
    alias gemr='run gem uninstall'
    alias gems='run gem search --remote'
    alias gemg='gem list | g'
    alias gemq='run gem specification --remote'
    # alias gemsync=
    alias gemupgrade='run gem update'
    alias gemoutdated='run gem outdated'
}

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
HAVE pacman && {
    alias pac='pacman'; TCOMP pacman pac
    alias paci='run pacman --sync --needed'; complete -F __pacman_sync__ paci
    alias pacidep='run pacman --sync --needed --asdeps'; complete -F __pacman_sync__ pacidep
    alias pacr='run pacman --remove --recursive'; complete -F __pacman_pkgs__ pacr
    alias pacs='run pacman --sync --search'; complete -F __pacman_sync__ pacs
    alias pacg='run pacman --query --search'; complete -F __pacman_pkgs__ pacg
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
    }; complete -F __pacman_pkgs__ pacq
    alias pacsync='run pacman --sync --refresh'
    alias pacupgrade='run pacman --sync --refresh --sysupgrade'
    alias pacoutdated='run pacman --query --upgrades; run pacckalts; run pacaur --check $(pacforeign)'
    alias pacclean='run pacman --sync --clean --noconfirm'
    alias pacorphans='run pacman --query --deps --unrequired'
    alias paclog='pager /var/log/pacman.log'
    alias pacowner='run pacman --query --owns'

    alias packey='pacman-key'; TCOMP pacman-key packey

    alias mkp='makepkg'; __longopt__ mkp
    alias mkpf='makepkg --force'; __longopt__ mkpf
    alias mkpo='makepkg --nobuild'; __longopt__ mkpo

    TCOMP find pacfindunknown

    _xspecs['pacinstallfile']='!*.pkg.tar.+([a-z])'
    complete -F _filedir_xspec pacinstallfile

    complete -F __pacdowngrade__ pacdowngrade
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
alias geom='identify -format "%wx%h	%f\n"'

# feh
HAVE feh && {
    alias fshow='feh --sort=dirname --recursive'; TCOMP feh fshow
    alias frand='feh --sort=dirname --recursive --randomize'; TCOMP feh frand
    alias ftime='feh --sort mtime'; TCOMP feh ftime
    alias fmove='fehmove'
    alias fcopy='fehmove --copy'
}

# pulseaudio
HAVE pulseaudio && {
    alias pastart='run pulseaudio --start'
    alias pastop='run pulseaudio --kill'
    alias parestart='run pulseaudio --kill; while pkill --exact -0 pulseaudio; do sleep 0.1; done; run pulseaudio --start'
}

# youtube-dl
TCOMP youtube-dl yt
TCOMP youtube-dl yt1080
TCOMP youtube-dl ytv
TCOMP youtube-dl ytx

### X

HAVE startx && alias xstartx='exec startx &>/dev/null'

### TTY

alias rl='rlwrap'; TCOMP exec rl

### Init

if HAVE systemctl; then
    alias sc='systemctl'; TCOMP systemctl sc
    alias scu='systemctl --user'; TCOMP systemctl scu
    alias jc='journalctl'; TCOMP journalctl jc
    alias jcu='journalctl --user'; TCOMP journalctl jcu
    alias jcb='journalctl --boot'; TCOMP journalctl jcb
    alias jce='journalctl --pager-end'; TCOMP journalctl jce
    alias jcf='journalctl --follow'; TCOMP journalctl jcf
    alias jcs='journalctl --since'
    alias jcverify='journalctl --verify'; TCOMP journalctl jcverify
    alias mc='machinectl'; TCOMP machinectl mc
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

alias kf='kupfer'

: # Return true
