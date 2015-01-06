###
### BASH FUNCTIONS, ALIASES, and VARIABLES
###
### Requires ~/.bashrc.d/functions.bash
###

### Command flags

command ls --color ~    &>/dev/null && GNU_COLOR_OPT='--color'
command grep -P . <<< . &>/dev/null && GREP_PCRE_OPT='-P'
command lsof +fg -h     &>/dev/null && LSOF_FLAG_OPT='+fg'
GC_VARS GNU_COLOR_OPT GREP_PCRE_OPT LSOF_FLAG_OPT

### Meta Utility Functions

alias bashnilla='env -i bash --norc --noprofile'

# Show commands shadowed by aliases and functions
shadowenv() {
    local cmd buf

    cat <(alias | ruby -e 'puts $stdin.read.scan(/^alias (.*?)=/).map { |(a)| a }') \
        <(set | grep '^[^ ]* ()' | awk '{print $1}') |
    while builtin read cmd; do
        buf="$(type -a "$cmd" | grep "$cmd is ")"
        if (($(grep -c . <<< "$buf") > 1)); then
            printf "%s\n\n" "$buf"
        fi
    done
}

# Return absolute path
# Param: $1 Filename
expand_path() { ruby -e 'print File.expand_path(ARGV.first)' -- "$1"; }

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
            paths = ENV[ARGV[0]].split ":"
            dir = File.expand_path ARGV[1]
            abort unless File.directory? dir
            puts paths.reject { |d| d == dir }.unshift(dir).join(":")
        ' -- "$var" "$dir")"; then
            export "$var=$newpath"
            echo "$var=$newpath"
        fi
    done
}

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

# Check shell init files and system paths for loose permissions
checkperm() {
    # path:user:group:octal-mask:options; all fields optional
    local specs=(
        /etc/.git:root:root:0077:no-recurse
        /etc:root
        ~/.bashrc
        ~/.bash_profile
        ~/.bash_login
        ~/.profile
        ~/.bash_logout
        ~/.bashrc.d
        ~/.bash_history
        ~/.bash_completion
        ~/.bash_completion.d
        ~/.bash_local
        ~/.inputrc
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
        specs+=("$f":root:root:0177)
    done

    local IFS=':'
    specs+=($PATH $LD_LIBRARY_PATH ${BASH_COMPLETION_DIRS[@]} $MAILPATH)
    unset IFS

    checkpermissions -- "${specs[@]}"
}

### Directories

CD_FUNC -n ..           ..
CD_FUNC -n ...          ../..
CD_FUNC -n ....         ../../..
CD_FUNC -n .....        ../../../..
CD_FUNC -n ......       ../../../../..
CD_FUNC -n .......      ../../../../../..
CD_FUNC -n ........     ../../../../../../..
CD_FUNC -x cdhaus       ~/.haus /opt/haus
CD_FUNC cdetc           /etc
CD_FUNC cdmnt           /mnt
CD_FUNC cdbrew          /opt/brew
CD_FUNC -x cddnsmasq    /etc/dnsmasq /opt/dnsmasq/etc
CD_FUNC -x cdnginx      /etc/nginx /opt/nginx/etc /usr/local/etc/nginx
CD_FUNC cdtmp           ~/tmp "$TMPDIR" /tmp
CD_FUNC cdvar           /var
CD_FUNC cdlog           /var/log
CD_FUNC cdpacmancache   /var/cache/pacman/pkg
CD_FUNC cdwww           /srv/http /srv/www /var/www
CD_FUNC -x cdapi        "$cdwww/api.dev"
CD_FUNC cdgunsrepl      "$cdhaus/etc/%local/%lib/clojure/guns"
CD_FUNC cdconfig        ~/.config
CD_FUNC cdlocal         ~/.local /usr/local
CD_FUNC cdLOCAL         /usr/local
CD_FUNC cdpass          ~/.password-store
CD_FUNC -x cdsrc        ~/src ~guns/src /usr/local/src
CD_FUNC cdSRC           "$cdsrc/READONLY"
CD_FUNC cdarchlinux     "$cdsrc/archlinux"
CD_FUNC cdvimfiles      "$cdsrc/vimfiles"
CD_FUNC cdjdk           "$cdSRC/openjdk/src/share"
CD_FUNC cddownloads     ~/Downloads ~guns/Downloads
CD_FUNC cddesktop       ~/Desktop
CD_FUNC cdmail          ~/Mail ~guns/Mail
CD_FUNC cdorg           ~/Documents/Org ~guns/Documents/Org

### Bash builtins and Haus commands

ALIAS cv='command -v'
alias h='history'
ALIAS j='jobs'
alias o='echo'
alias p='pushd .'
alias pp='popd'
alias rehash='hash -r'
ALIAS t='type --' \
      ta='type -a --' \
      tp='type -P --'
ALIAS x='exec'
alias wrld='while read l; do'; TCOMP exec wrld
ALIAS comp='complete -p'
__compreply__() {
    local cur
    _get_comp_words_by_ref cur
    COMPREPLY=($(compgen -W "$*" -- "$cur"));
}

# PATH prefixer
path() { __prepend_path__ PATH "$@"; }
ldpath() { __prepend_path__ LD_LIBRARY_PATH "$@"; }

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
        xecho title 'nohist'
    else
        HISTFILE="${HISTFILE_DISABLED:-$HOME/.bash_history}"
        unset HISTFILE_DISABLED
        xecho title 'HIST'
    fi
    __ps1toggle__ '/\\H/[nohist] \\H'
}

# notify
ALIAS n='notify' \
      na='notify --audio'

# run bgrun
HAVE run   && TCOMP exec run
HAVE bgrun && TCOMP exec bgrun

### Files, Disks, and Memory

# grep
ALIAS g="grep -i $GREP_PCRE_OPT $GNU_COLOR_OPT" \
      gw='g -w' \
      gv='g -v'
alias wcl='grep -c .'

# ag
ALIAS agi='ag -i' \
      agq='ag -Q' \
      agiq='ag -iQ'

# cat less tail
alias c='cat'
ALIAS l='less' \
      L='l +S' \
      lf='l +F' && pager() { less -+c --quit-if-one-screen "$@"; }
ALIAS tf='tail -f'

if [[ -e /var/log/everything.log ]]; then
    ALIAS lfsyslog='lf /var/log/everything.log'
    ALIAS tfsyslog='tf /var/log/everything.log'
elif [[ -e /var/log/system.log ]]; then
    ALIAS lfsyslog='lf /var/log/system.log'
    ALIAS tfsyslog='tf /var/log/system.log'
elif [[ -e /var/log/syslog ]]; then
    ALIAS lfsyslog='lf /var/log/syslog'
    ALIAS tfsyslog='tf /var/log/syslog'
fi

# ls
alias ls="ls -Ahl $GNU_COLOR_OPT"
alias lc='ls -C'
alias lsd='ls -d'
alias lsr='ls -R'; lsrl() { ls -R "${@:-.}" | pager; }
alias lst='ls -t'; lstl() { ls -t "${@:-.}" | pager; }
alias l1='command ls -1'
alias l1g='l1 | g'
alias l1gv='l1 | gv'
alias lsg='ls | g'
alias lsgv='ls | gv'
if __DARWIN__; then
    alias ls@='ls -@'
    alias lse='ls -e'
fi
HAVE lsblk && {
    lsb() {
        if (($#)); then
            lsblk -a "$@"
        else
            lsblk -ao NAME,SIZE,RM,RO,TYPE,FSTYPE,LABEL,MOUNTPOINT
        fi
    }
    alias lsbfs='lsb -f'
    alias lsbmode='lsb -m'
    alias lsbscsi='lsb -S'
}
[[ -d /dev/mapper ]] && alias lsmapper='ls /dev/mapper'
# Param: $1 Directory to list
# Param: $2 Interior of Ruby block with filename `f`
__lstype__() {
    ruby -e '
        if ARGV.first == "-q"
            require "shellwords"
            quote = true
            ARGV.shift
        end
        Dir.chdir ARGV.first do
            fs = Dir.entries(".").reject { |e| e =~ /\A\.{1,2}\z/ }.select { |f|
                eval ARGV[1]
            }.sort
            fs.map! { |f| f.shellescape.shellescape } if quote
            puts fs
        end
    ' -- "$@"
}
ls.() { __lstype__ "${1:-.}" 'f =~ /\A\./'; }
lsl() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "link"'; }
lsx() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "file" and File.executable? f'; }
lsdir() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "directory"'; }

# objdump hexdump strings readelf hexfiend
HAVE hexdump && { hex() { hexdump -C "$@" | pager; }; TCOMP hexdump hex; }
HAVE objdump && { ox() { objdump -x "$@" | pager; }; TCOMP objdump ox; }
HAVE readelf && { dl() { readelf -d "$@" | pager; }; TCOMP readelf dl; }
HAVE strings && strings() { command strings -a -tx - "$@" | pager; }
HAVE '/Applications/Hex Fiend.app/Contents/MacOS/Hex Fiend' && {
    alias hexfiend='open -a "/Applications/Hex Fiend.app"'
}

# find
f()  { find-wrapper                                    --  "$@"; }; TCOMP find f
f1() { find-wrapper --pred '-maxdepth 1'               --  "$@"; }; TCOMP find f1
ff() { find-wrapper --pred '( -type f -o -type l )'    --  "$@"; }; TCOMP find ff
fF() { find-wrapper --pred '-type f'                   --  "$@"; }; TCOMP find fF
fd() { find-wrapper --pred '-type d'                   --  "$@"; }; TCOMP find fd
fl() { find-wrapper --pred '-type l'                   --  "$@"; }; TCOMP find fl
fnewer() { find-wrapper --pred '-newer /tmp/timestamp' --  "$@"; }; TCOMP find fnewer
tstamp() { run touch /tmp/timestamp; }
cdf() {
    cd "$(ruby -r find -e '
        pat, dst = Regexp.new(ARGV.first), "."
        Find.find "." do |path|
            next unless File.directory? path
            (dst = path; break) if path =~ pat
        end
        puts dst
    ' -- "$@")"
}; TCOMP find cdf

# cp mv
alias cp='cp -v'
alias cpn='cp -n'
alias cpr='cp -r'
alias cprn='cpr -n'
alias mv='mv -v'
alias mvn='mv -n'

# rm
alias rm='rm -v'
alias rmf='rm -f'
alias rmrf='rm -rf'
rm-craplets() {
    run find "${1:-.}" \( -name '.DS_Store' -o -name 'Thumbs.db' \) -type f -print -delete
}

# ln
alias ln='ln -v'
alias lns='ln -s'
alias lnsf='lns -f'
lnnull() { run rm -rf "${1%/}" && run ln -sf /dev/null "${1%/}"; }
lndesktop() {
    if (($# == 1)) && [[ ! -d ~/Desktop ]] && [[ -d "$1" ]]; then
        local src="$(expand_path "$1")"
        (cd; rm -f Desktop; ln -sv "$src" Desktop)
    fi
}

# chmod chown touch
alias chmod='chmod -v'
alias chmodr='chmod -R'
alias chmodx='chmod +x'
alias chown='chown -v'
ALIAS chownr='chown -R'

# mkdir
ALIAS md='mkdir -vp'
ALIAS rd='rmdir -vp'

# df du
alias df='df -h'
alias du='du -h'
alias dus='du -s'

# mount
ALIAS mt='mount -v -o noatime' \
      umt='umount -v' && {
    alias mtusb='mountusb' \
          umtusb='umountusb'
    remt() { run mount -v -o "remount,$2" "$1" "${@:3}"; }
    mtlabel() {
        (($# >= 2)) || { echo "$FUNCNAME label mount-args" >&2; return 1; }
        run mount -o noatime "/dev/disk/by-label/$1" "${@:2}"
    }
    _mtlabel() {
        if ((COMP_CWORD == 1)); then
            __compreply__ "$(command ls -1 /dev/disk/by-label/)";
        else
            _load_comp mount
            _mount
        fi
    }
    complete -F _mtlabel mtlabel
}

# findmnt
ALIAS fm='findmnt'

# fusermount
ALIAS fusermt='fusermount -o noatime' \
      fuserumt='fusermount -u'

# tar
alias star='tar --strip-components=1'
alias gtar='tar zcv'
alias btar='tar jcv'
alias xtar='tar Jcv'
alias lstar='tar tvf'
# Option: -S Strip one level of directories
# Param:  $@ Arguments to `tar`
untar() {
    local opts=() f
    [[ "$1" == '-S' ]] && { opts+=(--strip-components=1); shift; }
    [[ -f "$1" ]] && f='f';
    run tar xv$f "$@" "${opts[@]}"
}
suntar() { untar -S "$@"; }
guntar() { untar -z "$@"; }
buntar() { untar -j "$@"; }
xuntar() { untar -J "$@"; }

# open
alias op='open 2>/dev/null'

# pax
ALIAS gpax='pax -z' && {
    # Param: $1 pax archive
    lspax() {
        local zip
        [[ "$1" == *.gz ]] && zip='-z'
        pax "$zip" < "$1"
    }

    unpax() {
        # Param: $1 pax archive
        # Param: $2 Directory to extract to
        ruby -r fileutils -r shellwords -e "
            abort 'Usage: $FUNCNAME archive basedir' unless ARGV.size == 2

            include FileUtils::Verbose

            archive, basedir = ARGV.map { |f| File.expand_path f }
            zip = '-z' if File.extname(archive) == '.gz'
            cmd = %Q(pax -r #{zip} < #{archive.shellescape})

            mkdir_p basedir
            chdir basedir
            puts cmd
            system cmd
        " -- "$@"
    }
}

# pkgutil
HAVE pkgutil && {
    # Param: $1 Package file
    # Param: $2 Directory to extract to
    pkgexpand() {
        (($# == 2)) || { echo "Usage: $FUNCNAME pkg dir"; return 1; }
        run pkgutil --expand "$1" "$2";
    }
}

# hdiutil diskutil
HAVE hdiutil diskutil && {
    alias disklist='diskutil list'
    alias diskinfo='diskutil info'
    alias corestorage='diskutil coreStorage'
    alias hattach='hdiutil attach'
    alias hdetach='hdiutil detach'
    alias hmount='hdiutil mount'
    alias humount='hdiutil unmount'
}

# rsync
ALIAS rsync='rsync -hh -S --partial' \
      rsync-backup='rsync -axAX --hard-links --delete --ignore-errors'

# dd
HAVE dcfldd && TCOMP dd dcfldd
HAVE ddsize && TCOMP dd ddsize

# free
ALIAS free='free --human'

# Plist dumper
ALIAS pbuddy='/usr/libexec/PlistBuddy' && {
    alias pprint='pbuddy -c Print'
    # Param: $1 Application directory
    appvers() {
        while (($#)); do
            local base="$1"
            shift
            [[ -e "$base/Contents/Info.plist" ]] || continue
            /usr/libexec/PlistBuddy -c Print "$base/Contents/Info.plist" |
                awk -F= '/CFBundleShortVersionString/{print $2}' |
                sed 's/[ ";]//g'
        done
    }
}

# Remove logs and caches
if __DARWIN__; then
    flushcache() {
        local dir cachedirs=(
            "$HOME/Library/Preferences/Macromedia/Flash Player"
            "$HOME/Library/Application Support/Microsoft/Silverlight"
            "$HOME/Library/Caches"
            "$HOME/Library/Logs"
        )

        ((EUID == 0)) && cachedirs+=(
            /Library/Caches
            /Library/Logs
            /var/log
            /opt/nginx/var/log
        )

        for dir in "${cachedirs[@]}"; do
            if [[ ! -d "$dir" ]]; then
                echo "Does not exist: \`$dir\`"
            elif [[ -w "$dir" ]]; then
                run find "$dir/" -type f -print -delete
            else
                echo "No permissions to write \`$dir\`"
            fi
        done
    }
fi

# MIME type handlers
ALIAS lsregister='/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister'

# Filesystem watcher
listen() {
    (($# == 2)) || { echo "Usage: $FUNCNAME path shellcmd"; return 1; }

    ruby -r listen -e '
        arg = File.expand_path ARGV[0]
        cmd = ARGV[1]
        d, f = File.directory?(arg) ? [arg, nil] : [File.dirname(arg), File.basename(arg)]
        λ = Proc.new { |m,a,r| system cmd unless m.empty? }
        l = Listen.to d
        l.filter Regexp.new("\\A" + Regexp.escape(f) + "\\z") if f
        l.change &λ
        l.start!
    ' -- "$1" "$2"
}

ALIAS iotop='iotop --only'

# Linux /proc /sys swap
__LINUX__ && {
    drop_caches() {
        local cmd='echo 3 > /proc/sys/vm/drop_caches'
        echo "$cmd"
        eval "$cmd"
    }

    sysrq() {
        if (($#)); then
            echo "$@" > /proc/sys/kernel/sysrq
        else
            cat /proc/sys/kernel/sysrq
        fi
    }

    alias swapin='swapoff -av; swapon -av'
}

### Processes

# kill
ALIAS k='kill' \
      k9='kill -9' \
      khup='kill -HUP' \
      kint='kill -INT' \
      kstop='kill -STOP' \
      kcont='kill -CONT' \
      kusr1='kill -USR1' \
      kquit='kill -QUIT'
ALIAS ka='killall -e -v' \
      ka9='ka -9' \
      kahup='ka -HUP' \
      kaint='ka -INT' \
      kastop='ka -STOP' \
      kacont='ka -CONT' \
      kausr1='ka -USR1' \
      kaquit='ka -QUIT'
ALIAS pk='pkill -x' \
      pk9='pk -9' \
      pkhup='pk -HUP' \
      pkint='pk -INT' \
      pkstop='pk -STOP' \
      pkcont='pk -CONT' \
      pkusr1='pk -USR1' \
      pkquit='pk -QUIT'

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
alias psgv='psa | grep -v "grep -i" | gv'
# BSD ps supports `-r` and `-m`
if ps ax -r &>/dev/null; then
    psr() { psa -r "$@" | pager; }
    psm() { psa -m "$@" | pager; }
# GNU/Linux ps supports `k` and `--sort`
else
    psr() { psa k-pcpu "$@" | pager; }
    psm() { psa k-rss  "$@" | pager; }
fi
ALIAS pst='pstree'

# htop
HAVE htop && {
    # Satisfy ncurses hard-coded TERM names
    alias htop='envtmux htop'

    # htop writes its config file on exit
    htopsave() { (cd && exec gzip -c .htoprc > "$cdhaus/share/conf/htoprc.gz") }
    htoprestore() { (cd && exec gunzip -c "$cdhaus/share/conf/htoprc.gz" > .htoprc) }
}

### Switch User

ALIAS s='sudo -H' \
      root='exec sudo -Hs' \
      asguns='sudo -Hu guns'
HAVE su && alias xsu='exec su' && TCOMP su xsu

### Network

if HAVE ip; then
    alias a='ip addr'
    alias cidr='ip route list scope link | awk "{print \$1; exit}"'
elif HAVE ifconfig; then
    alias ic='ifconfig'
fi
ALIAS airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport' \
      ap='airport'
ALIAS net='netctl' \
      netstop='netctl stop-all'

# cURL
ALIAS get='curl -A Mozilla/5.0 -#L' \
      geto='curl -A Mozilla/5.0 -#LO'

# DNS
ALIAS digx='dig -x' \
      digs='dig +short'
if __DARWIN__; then
    alias resolv='ruby -e "puts %x(scutil --dns).scan(/resolver #\d\s+nameserver\[0\]\s+:\s+[\h.]+/)"'
else
    alias resolv='{
        printf "\e[32;1m/etc/resolv.conf\e[0m\n"
        cat /etc/resolv.conf
        printf "\n\e[32;1m/etc/dnsmasq/resolv.conf\e[0m\n"
        cat /etc/dnsmasq/resolv.conf
    } | grep -vP "^#|^\s*$"'
fi

# NTP
ALIAS qntp='ntpd -g -q'

# netcat
HAVE nc   && complete -F _known_hosts nc
HAVE ncat && complete -F _known_hosts ncat

# tcpdump
HAVE tcpdump && {
    alias pcapdump='tcpdump -n -XX -r'
}

# ssh scp
ALIAS ssh='ssh -2' \
      ssh-password='ssh -o "PreferredAuthentications password"'
alias ssh-remove-host='ssh-keygen -R' && complete -F _known_hosts ssh-remove-host
ALIAS scp='scp -2' \
      scpr='scp -r'
HAVE ssh-shell && alias xssh-shell='exec ssh-shell'
HAVE ssh-proxy && TCOMP ssh ssh-proxy
HAVE sshuttle && {
    TCOMP ssh sshuttle
    TCOMP ssh sshuttle-wrapper
}

# lsof
ALIAS lsof="lsof -Pn $LSOF_FLAG_OPT" && {
    alias lsif='lsof -i'
    alias lsifr="command lsof -Pi $LSOF_FLAG_OPT"
    alias lsifudp='lsif | grep UDP'
    alias lsiflisten='lsif | grep -w "LISTEN\|UDP"'
    alias lsifconnect='lsif | grep -- "->"'
    alias lsifconnectr='lsifr | grep -- "->"'
    alias lsuf='lsof -U'
}

# nmap
HAVE nmap && {
    alias nmapsweep='run nmap -sU -sS --top-ports 50 -O -PE -PP -PM "$(cidr)"'
}

HAVE ngrep && {
    # FIXME: https://bbs.archlinux.org/viewtopic.php?pid=1358365#p1358365
    # alias ngg='ngrep -c 0 -d any -l -q -P "" -W byline'
    alias ngg='tcpdump -i any -w - | ngrep -c 0 -l -q -P "" -W byline -I -'
}

# scutil
HAVE scutil && {
    # Param: [$*] New hostname
    sethostname() {
        local pref keys=(ComputerName LocalHostName HostName)
        if (($#)); then
            for pref in "${keys[@]}"; do
                scutil --set $pref "$*"
            done
            "$FUNCNAME"
        else
            for pref in  "${keys[@]}"; do
                printf "$pref: "
                scutil --get $pref
            done
        fi
    }
}

# Weechat
HAVE weechat && {
    ((EUID > 0)) && alias irc='(cd ~/.weechat && envtmux weechat)'
}

# Local api server @ `$cdapi`
HAVE cdapi && {
    # Param: $@ API Site names
    api() { local d; for d in "$@"; do open "http://${cdapi##*/}/$d"; done; }
    _api() { __compreply__ "$(lsdir "$cdapi")"; }
    complete -F _api api
}

# Simple webserver
httpserver() { rackup -b 'run Rack::Directory.new(ARGV.first || ".")' "$@"; }

# w3m
ALIAS W='w3mlaunch'

### Firewalls

# iptables
[[ -x /etc/iptables/iptables.sh ]] && alias iptables.sh='run /etc/iptables/iptables.sh'

### Editors

# Exuberant ctags
ALIAS ctagsr='ctags -R'

# Vim
HAVE vim && {
    alias v='vim -c "set nomodified" -'
    vimnilla() {
        local OPTIND OPTARG opt dirs=()
        while getopts :d: opt; do
            case $opt in
            d) dirs+=("$OPTARG");;
            esac
        done
        shift $((OPTIND-1))

        command vim -N -u <(ruby -r shellwords -e '
            puts %q{set rtp^=%s | filetype plugin indent on | syntax on} % ARGV.map(&:shellescape).join(",")
        ' -- "${dirs[@]}") -U NONE "$@"
    }
    vimopen() { vim -c 'UniteOpen' "$@"; }

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
            vimopen
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

        (( ${#args[@]} )) && run vim "${args[@]}"
    }

    vimsession() {
        local session="$HOME/.cache/vim/session/$(pwd -P)/Session.vim"
        if [[ -e "$session" ]]; then
            vim -S "$session" -c "silent! execute '! rm -f ' . v:this_session" "$@"
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

    # Frequently edited files
    alias vimautocommands='(cdhaus && exec vim etc/vim/local/autocommands.vim)'
    alias vimaliases='(cd ~/.mutt && exec vim aliases)'
    alias vimbashinteractive='(cdhaus && exec vim etc/bashrc.d/interactive.bash)'
    alias vimbashrc='(cdhaus && exec vim etc/bashrc)'
    alias vimcommands='(cdhaus && exec vim etc/vim/local/commands.vim)'
    alias vimdnsmasq='(cddnsmasq && exec vim dnsmasq.conf)'
    alias vimgitexclude='vim "$(git rev-parse --show-toplevel)/.git/info/exclude"'
    alias vimsparsecheckout='vim "$(git rev-parse --show-toplevel)/.git/info/sparse-checkout"'
    alias vimgunsrepl='(cdgunsrepl && exec vim src/guns/repl.clj)'
    alias viminputrc='(cdhaus && exec vim etc/inputrc)'
    alias vimiptables='(cdetc && exec vim iptables/iptables.sh)'
    alias vimmappings='(cdhaus && exec vim etc/vim/local/mappings.vim)'
    alias vimmuttrc='(cdhaus && exec vim etc/%mutt/muttrc)'
    alias vimnginx='(cdnginx && exec vim nginx.conf)'
    alias vimorg='vim -c Org!'
    alias vimpacman='(cdetc && exec vim pacman.conf)'
    alias vimleinprofiles='(cdhaus && exec vim etc/%lein/profiles.clj)'
    alias vimleinsampleproject='vim "$cdsrc/leiningen/sample.project.clj"'
    alias vimhausrakefile='(cdhaus && exec vim Rakefile)'
    alias vimscratch='vim -c Scratch'
    alias vimsshconfig='(cd ~/.ssh && exec vim config)'
    alias vimtodo='vim -c "Org! TODO"'
    alias vimtmux='(cdhaus && exec vim etc/tmux.conf)'
    alias vimunicode='(cdhaus && exec vim share/doc/unicode-table.txt.gz)'
    alias vimrc='(cdhaus && exec vim etc/vimrc)'
    alias vimperatorrc='(cdhaus && exec vim etc/vimperatorrc)'
    alias vimwm='(cdhaus && exec vim -O etc/%config/{bspwm/bspwmrc,sxhkd/sxhkdrc})'
    alias vimxinitrc='vim ~/.xinitrc'
    alias vimxautostart='(cdhaus && exec vim etc/%config/bspwm/autostart)'
}

# Emacs
HAVE emacs && alias emacsparedit='PAREDIT=1 emacs'

### Terminal Multiplexers

# Tmux
ALIAS tm='tmux' && {
    HAVE tmuxlaunch && alias xtmuxlaunch='exec tmuxlaunch'

    tmuxeval() {
        local vars=$(sed "s:^:export :g" <(tmux show-environment | grep -E "^[A-Z_]+=[a-zA-Z0-9/.-]+$"))
        echo "$vars"
        eval "$vars"
    }
}

envtmux() {
    run env $([[ $TERM == tmux* ]] && echo TERM=screen-256color) "$@"
}; TCOMP exec envtmux

# GNU screen
HAVE screen && {
    alias screenr='screen -R'
    alias xscreenr='exec screen -R'; TCOMP screen xscreenr
}

### Compilers

# make
ALIAS mk='make' \
      mkclean='make clean' \
      mkdistclean='make distclean' \
      mkinstall='make install' \
      mkj='make -j\$\(grep -c ^processor /proc/cpuinfo\)' \
      mkj2='make -j2' \
      mkj4='make -j4' \
      mkj8='make -j8' \
      mke='make -e' \
      mkej='make -ej\$\(grep -c ^processor /proc/cpuinfo\)' \
      mkb='make -B' \
      mkbj='mkj -B' && cdmkinstall() { (cd "$@"; make install) }

### SCM

# diff patch
ALIAS di='diff -U3' \
      diw='di -w' \
      dir='di -r' \
      diq='di -q' \
      dirq='di -rq'
ALIAS patch='patch --version-control never'

# git
HAVE git && {
    alias git='GIT_SSL_CAINFO=~/.certificates/github.crt git'
    alias gitgc='run git gc --aggressive --prune=all'

    # Github
    # Param: $1   User name
    # Param: $2   Repository name
    # Param: [$3] Branch name
    githubclone() {
        (($# == 1 || $# == 2)) || { echo "Usage: $FUNCNAME user/repo [branch]"; return 1; }
        local user="${1%%/*}" repo="${1#*/}" branch
        [[ $2 ]] && branch="--branch $2"
        run git clone $branch "git@github.com:${user}/${repo}"
    }

    # PS1 git status
    REQUIRE ~/.bashrc.d/git-prompt.sh
    gitps1() {
        __ps1toggle__ '/\\w/\\w\$(__git_ps1 \" → \\[\\033[3m\\]%s\\[\\033[23m\\]\")'
    }; gitps1
}
githubget() {
    (($# == 2 || $# == 3)) || { echo "Usage: $FUNCNAME user/repo [branch]"; return 1; }
    local user="${1%%/*}" repo="${1#*/}" branch="${2:master}"
    run curl -#L "https://github.com/$user/$repo/tarball/$branch"
}

archivesrc() {
    local d
    for d in "$@"; do
        local dirname="$(basename "$d")"
        local archive="$cdsrc/ARCHIVE/$dirname".tar.xz
        pushd . >/dev/null
        cd "$d"
        git fdx
        git gc --aggressive --prune=all
        cd ..
        if run tar acf "$cdsrc/ARCHIVE/$dirname".tar.xz "${d%/}"; then
            run rm -rf "$d"
            command du -h "$archive"
        fi
        popd >/dev/null
    done
}

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
                local cx='cert exec -f ~/.certificates/rubygems.crt --'
                # alias geme
                alias "gem${suf}g=$cx ${bin}/gem list | g"
                alias "gem${suf}i=$cx ${bin}/gem install"
                alias "gem${suf}q=$cx ${bin}/gem specification -r"
                alias "gem${suf}s=$cx ${bin}/gem search -r"
                alias "gem${suf}r=$cx ${bin}/gem uninstall"
                # alias gemsync
                alias "gem${suf}outdated=$cx ${bin}/gem outdated"
            }

            # IRB
            if [[ "$suf" == 18* ]]; then
                ALIAS "irb${suf}=${bin}/irb -Ku"
            else
                ALIAS "irb${suf}=${bin}/irb"
            fi

            # Rake
            ALIAS "rake${suf}=${bin}/rake" \
                  "rk${suf}=rake${suf}" \
                  "rk${suf}t=rake${suf} -T"

            # Useful gem executables
            ALIAS "b${suf}=${bin}/bundle" \
                  "bx${suf}=${bin}/bundle exec" \
                  "brk${suf}=${bin}/bundle exec rake" \
                  "brk${suf}t=${bin}/bundle exec rake -T" \
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
    rbopt() { run env RUBYOPT=$1 "${@:2}"; }

    # PATH variables
    rubylib() { __prepend_path__ RUBYLIB "$@"; }
    gempath() { path "${@:-.}/bin"; rubylib "${@:-.}/lib"; }

    # Rails
    r() {
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
    }

    rklink() {
        case $# in
        0) local fname="${PWD##*/}";;
        1) local fname="$1";;
        *) echo "USAGE: $FUNCNAME [srcname]"; return 1;;
        esac

        local src="$cdhaus/share/rake/$fname"
        if [[ -e "$src" ]]; then
            ln -s "$src" Rakefile
        else
            echo "$src does not exist!"
            return 1
        fi
    }
}

### Python

ALIAS py='python'

### JVM

# Leiningen
HAVE lein && {
    alias lein='run cert exec -f ~/.certificates/leiningen.crt -k ~/.certificates/leiningen.ks -- lein'

    # alias leine=
    # alias leing=
    alias leini='run lein install'
    # alias leinq=
    alias leins='run lein search'
    # alias leinu=
    # alias leinsync=
    alias leinoutdated='lein ancient :all :check-clojure :allow-qualified :allow-snapshots'
}

ALIAS java-share-dump='java -server -Xshare:dump'
ALIAS ngstop='ng ng-stop'

### JavaScript

# node package manager
ALIAS npm='npm --global' && {
    # alias npme
    alias npmg='run npm ls | g'
    alias npmi='run npm install --global'
    alias npmq='run npm view'
    alias npms='run npm search'
    alias npmu='run npm rm --global'
    # alias npmsync
    # alias npmoutdated
}

### Perl

ALIAS perlpe='perl -pe' \
      perlne='perl -ne' \
      perlpie='perl -i -pe' && {
    # http://www.toad.net/~jkaplan2/perlRepl.htm
    perlrepl() {
        perl -e '
            while (true)
            {
                print ">>> ";
                $line  = <>;
                $value = eval ($line);
                $error = $@;
                if ($error ne "") { print $error; } else { print "$value\n"; }
            }
        ' -- "$@"
    }
}

### Haskell

# cabal package manager
HAVE cabal && {
    # alias cabale
    alias cabalg='run cabal list installed'
    alias cabali='run cabal install'
    alias cabalq='run cabal info'
    alias cabals='run cabal list'
    alias cabalu='run ghc-pkg unregister'
    alias cabalsync='run cabal update'
    # alias cabaloutdated
}

### Databases

HAVE mysql && {
    mysql() { command mysql -uroot -p"$(pass "$HOSTNAME/mysql/root")" "${@:-mysql}"; }
    ALIAS mysqldump="mysqldump -uroot -p\"\\\$(pass "$HOSTNAME/mysql/root")\""
    ALIAS mysqladmin="mysqladmin -uroot -p\"\\\$(pass "$HOSTNAME/mysql/root")\""
}

HAVE psql && {
    ALIAS aspostgres='sudo -Hiu postgres'
}

ALIAS sqlite='sqlite3' && {
    sqlite-firefox-history() {
        (($# == 1)) || { echo "Usage: $FUNCNAME path/to/places.sqlite"; return 1; }
        # http://unfocusedbrain.com/site/2010/03/09/dumping-firefoxs-places-sqlite/
        sqlite3 "$@" <<-EOF
            SELECT datetime(moz_historyvisits.visit_date/1000000, 'unixepoch'), moz_places.url, moz_places.title, moz_places.visit_count
            FROM moz_places, moz_historyvisits
            WHERE moz_places.id = moz_historyvisits.place_id
            ORDER BY moz_historyvisits.visit_date DESC;
	EOF
    }
}

HAVE abook && abook() {
    if (($#)); then
        ruby -r shellwords -e '
            fmt = "{name}\x1e{nick}\x1e{email}\x1e{mobile}\x1e{phone}\x1e{workphone}\x1e{notes}"
            buf = %x(abook --mutt-query #{ARGV.shelljoin} --outformat custom --outformatstr #{fmt.shellescape})
            exit if $?.exitstatus != 0
            buf.each_line do |line|
                name, nick, email, mobile, phone, workphone, notes = line.split("\x1e").map { |f|
                    f unless f.nil? or f.empty?
                }
                puts "%-20s %-16s <%s>%s" % [
                    (nick || name),
                    mobile || phone || workphone,
                    email,
                    (" " + notes if notes)
                ]
            end
        ' -- "$@"
    else
        command abook
    fi
}

### Hardware control

ALIAS mp='modprobe -a'
ALIAS sens='sensors'
ALIAS trim='fstrim -av'

ALIAS rfk='rfkill' && {
    alias rfdisable='run rfkill block all'
    alias rfenable='run rfkill unblock all'
}

if __DARWIN__; then
    # Show all pmset settings by default
    # Param: [$@] Arguments to `pmset`
    pmset() {
        if (($#)); then
            command pmset "$@"
        else
            run command pmset -g custom
        fi
    }

    alias noidle='pmset noidle'
    alias pmassertions='pmset -g assertions'
fi

HAVE hdparm && {
    alias hdpowerstatus='hdparm -C'
    alias hdstandby='hdparm -y'
    alias hdsleep='hdparm -Y'
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
        bgrun wpa_supplicant -i "$iface" -c <(wpa_passphrase "$ssid" "$pass")
    }
}

### Encryption

# OpenSSL
ALIAS ssl='openssl' && {
    sslconnect() {
        case $# in
        1) local host="$1" port='443';;
        2) local host="$1" port="$2";;
        *) echo "Usage: $FUNCNAME host [port]"; return 1
        esac
        run openssl s_client -crlf -connect "$host:$port"
    }
}

# GnuPG
# HACK: This allows us to define a default encrypt-to in gpg.conf for
#       applications like mutt
if ALIAS gpg='gpg2 --no-encrypt-to' || ALIAS gpg='gpg --no-encrypt-to'; then
    ALIAS gpgverify='gpg --verify-files' \
          gpgsign='gpg --detach-sign'
    alias gpgkilldaemons='run gpgconf --kill gpg-agent; run gpgconf --kill dirmngr'
    alias xgpgshell='exec gpg-shell'
fi

# pass
HAVE pass && {
    # We want pc() to suppress the trailing newline
    pc() { pass "$@" | ruby -e 'print $stdin.gets("\n").chomp; warn $stdin.read' | clip; }; TCOMP pass pc
    passl() { pass "$@" | pager; }; TCOMP pass passl
    passi() { pass insert -fm "$1" < <(genpw "${@:2}") &>/dev/null; pass "$1"; }; TCOMP pass passi
    passiclip() { passi "$@" | clip; }; TCOMP pass passiclip
}

# cryptsetup
ALIAS cs='cryptsetup' && {
    TCOMP umount csumount
    alias csdump='cryptsetup luksDump'
    __crypt_names__() { __compreply__ "$(cat /sys/block/*/dm/name)"; }
    alias cssuspend='cryptsetup luksSuspend'; complete -F __crypt_names__ cssuspend
    alias csresume='cryptsetup luksResume'; complete -F __crypt_names__ csresume
}

HAVE cert && {
    cx() {
        local certfile=$(expand_path "~/.certificates/$1")
        local keystore=$(expand_path "~/.certificates/${1%.crt}.ks")

        if [[ -e "$keystore" ]]; then
            run cert exec -f "$certfile" -k "$keystore" -- "${@:2}"
        else
            run cert exec -f "$certfile" -- "${@:2}"
        fi
    }
    _cx() {
        if ((COMP_CWORD == 1)); then
            __compreply__ "$(command ls -1 ~/.certificates/ | grep '\.crt$')";
        else
            _command_offset 2
        fi
    }
    complete -F _cx cx
}

java-import-keystore() {
    (($# == 2)) || { echo "USAGE: $FUNCNAME crtfile keystore"; return 1; }
    run keytool -storepass changeit -importcert -file "$1" -keystore "$2"
}

if __DARWIN__; then
    alias list-keychains='find {~,,/System}/Library/Keychains -type f -maxdepth 1'
    alias security-dump-certificates='run security export -t certs'
fi

### Virtual Machines

# Docker
ALIAS d='docker'

# VMWare
ALIAS vmrun='/Library/Application\ Support/VMware\ Fusion/vmrun' && {
    vmtoggle() {
        if ifconfig vmnet1 &>/dev/null; then
            local flag='--stop'
        else
            local flag='--start'
        fi

        run "/Library/Application Support/VMware Fusion/boot.sh" $flag
    }
}

# VirtualBox
if [[ -d /Applications/VirtualBox.app ]]; then
    vboxtoggle() {
        local ids=(org.virtualbox.kext.VBoxDrv org.virtualbox.kext.VBoxNetAdp org.virtualbox.kext.VBoxNetFlt org.virtualbox.kext.VBoxUSB)
        if [[ -z $(kextstat -l -b "${ids[0]}") ]]; then
            run macdriver load -r /Library/Extensions "${ids[@]}"
        else
            run macdriver unload -r /Library/Extensions "${ids[@]}"
        fi
    }
fi

### Package Managers

if __DARWIN__; then
    # MacPorts package manager
    ALIAS port='port -c' && {
        porte() { local fs=() f; for f in "$@"; do fs+=("$(port file "$f")"); done; vim "${fs[@]}"; }
        alias portg='run port -c installed | g'
        alias porti='run port -c install'
        alias portq='run port -c info'
        alias ports='run port -c search'
        alias portr='run port -c uninstall'
        alias portsync='run port -c selfupdate'
        # alias portoutdated
    }

    # Homebrew package manager
    HAVE brew && {
        alias brewe='run brew edit'
        alias brewg='run brew list | g'
        alias brewi='run brew install'
        alias brewq='run brew info'
        alias brews='run brew search'
        alias brewr='run brew uninstall'
        alias brewsync='run sh -c "cd \"$(brew --prefix)\" && git checkout master && git pull && \
                                   git checkout guns && git merge master -m "Merge master into guns" && git push github --all"'
        alias brewoutdated='brew outdated'

        alias brewprefix='brew --prefix'
    }
elif __LINUX__; then
    # Aptitude package manager
    ALIAS apt='aptitude' && {
        apte() { vim "$(apt-file "$@")"; }
        alias aptg='run dpkg --list | g'
        alias apti='run aptitude install'
        aptq() {
            local pkg
            for pkg in "$@"; do
                aptitude show "$pkg"
                dpkg --listfiles "$pkg"
            done
        }
        alias apts='run aptitude search'
        alias aptr='run aptitude remove'
        alias aptsync='run aptitude update'
        alias aptupgrade='run aptitude safe-upgrade'
        # alias aptoutdated
    }

    # Pacman package manager
    ALIAS pac='pacman' && {
        # alias pace
        alias pacg='run pacman -Qs'
        alias paci='run pacman -S --needed'
        pacq() {
            local pkg
            for pkg in "$@"; do
                if pacman -Qi "$pkg"; then
                    pactree -r "$pkg"; echo
                    pacman -Ql "$pkg"; echo
                else
                    pacman -Si "$pkg"
                fi
            done 2>/dev/null | pager
        }
        alias pacs='run pacman -Ss'
        alias pacr='run pacman -Rs'
        alias pacsync='run pacman -Sy'
        alias pacupgrade='run pacman -Syu'
        alias pacoutdated='run pacman -Qu'

        alias pacclean='run pacman -Sc'
        alias pacforeign='run pacman -Qm'
        alias paclog='pager /var/log/pacman.log'

        pacfindunknown() {
            find "$@" -exec pacman -Qo -- {} + 2>&1 >/dev/null
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
            run pacman -U "${@/#//var/cache/pacman/pkg/}";
        }
        _pacdowngrade() { __compreply__ "$(command ls -1 /var/cache/pacman/pkg/ | grep '\.tar.xz$')"; }
        complete -F _pacdowngrade pacdowngrade

        ALIAS packey='pacman-key'
    }

    ALIAS mkp='makepkg' \
          mkpf='makepkg -f' \
          mkps='makepkg -s' \
          mkpa='makepkg -A'
fi

### Media

# Imagemagick
ALIAS geometry='identify -format \"%w %h\"'

# feh
HAVE feh && {
    ALIAS fshow='feh -r' \
          frand='feh -rz' \
          ftime='feh -Smtime'
    alias fmove='fehmove'
    alias fcopy='fehmove --copy'
}

# cmus
HAVE cmus && {
    alias cmus='envtmux cmus'
}

HAVE ffmpeg && {
    alias voicerecording='sleep 0.5; ffmpeg -f alsa -ac 2 -i pulse -acodec pcm_s16le -af bandreject=frequency=60:width_type=q:width=1.0 -y'
}

# VLC
[[ -x /Applications/VLC.app/Contents/MacOS/VLC ]] && {
    alias vlc='open -a /Applications/VLC.app'
}

# Quick Look (OS X)
HAVE qlmanage && alias ql='qlmanage -p'

# youtubedown
ALIAS youtubedown='youtubedown --verbose --progress' && {
    youtubedownformats() {
        youtubedown --verbose --size "$@" 2>&1 | ruby -Eiso-8859-1 -e '
            puts input = $stdin.readlines
            fmts = input.find { |l| l =~ /available formats:/ }[/formats:(.*);/, 1].scan /\d+/
            buf = File.readlines %x(/bin/sh -c "command -v youtubedown").chomp
            puts fmts.map { |f| buf.grep /^  # #{f}/ }
        '
    }
}

# mkvmerge
HAVE mkvmerge && mkvmergeout() {
    (($# > 1)) || { echo "USAGE: $FUNCNAME out-file [input-files …]"; return 1; }
    ruby -e '
        out, *inputs = ARGV
        args = [inputs.first] + (["+"] * (inputs.size - 1)).zip(inputs.drop 1)
        system "mkvmerge", "-o", out, *args.flatten
    ' -- "$@"
}

### X

HAVE startx && alias xstartx='exec startx &>/dev/null'

# GTK
HAVE gtk-update-icon-cache && gtk-update-icon-cache-all() {
    local dir
    for dir in ~/.icons/*; do
        [[ -d "$dir" ]] && run gtk-update-icon-cache -f -t "$dir"
    done
}

### TTY

ALIAS rl='rlwrap'

### Init

if HAVE systemctl; then
    ALIAS sc='systemctl' \
          jc='journalctl' \
          jcb='journalctl -b' \
          jce='journalctl -e' \
          jcf='journalctl -f' && {
        alias sctimers='systemctl list-timers'
        alias scunitfiles='systemctl list-unit-files'
        alias scrunning='systemctl list-units --state=running'
        alias scdaemonreload='systemctl --system daemon-reload'
    }
else
    RC_FUNC rcd /etc/{rc,init}.d /usr/local/etc/{rc,init}.d
fi

ALIAS lctl='launchctl' \
      lctlload='launchctl load -w' \
      lctlunload='launchctl unload -w' && {
    lctlreload() { run launchctl unload -w "$@"; run launchctl load -w "$@"; }
    lctlfind() {
        local dir
        for dir in {/System,~,}/Library/Launch{Agents,Daemons}; do
            [[ -d "$dir" ]] && f "$dir" "$@"
        done
    }
}

### GUI programs

if __DARWIN__; then
    # LaunchBar
    HAVE /Applications/LaunchBar.app/Contents/MacOS/LaunchBar && {
        alias lb='open -a /Applications/LaunchBar.app'
        # Param: $* Text to display
        largetext() {
            ruby -e '
                input = ARGV.first.empty? ? $stdin.read : ARGV.first
                msg = %Q(tell application "Launchbar" to display in large type #{input.inspect})
                system *%W[osascript -e #{msg}]
            ' -- "$*"
        }
    }

    ALIAS screensaverengine='/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine'
fi

ALIAS kf='kupfer' && {
    alias kfstart='(cddownloads && bgrun kupfer --no-splash)'
}

: # Return true
