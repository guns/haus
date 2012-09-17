### BASH FUNCTIONS, ALIASES, and VARIABLES ###

# Requires ~/.bashrc.d/functions.bash

### Environment Variables {{{1

# Bash history
export HISTSIZE='65535'
export HISTIGNORE='&:cd:.+(.):ls:lc: *' # Ignore dups, common commands, and leading spaces

# Editor
export EDITOR='vim'
export VISUAL='vim'

# Locales
export LANG='en_US.UTF-8'               # UTF-8 ftw
export LC_CTYPE='en_US.UTF-8'           # Rxvt-unicode needs this set explicitly
export LC_COLLATE='C'                   # Traditional ASCII sorting

# BSD and GNU colors
export CLICOLOR='1'
export LSCOLORS='ExFxCxDxbxegedabagacad'
export LS_COLORS='di=01;34:ln=01;35:so=01;32:pi=01;33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:ow=30;42:tw=30;43'

# Command flags
command ls --color ~    &>/dev/null && GNU_COLOR_OPT='--color'
command grep -P . <<< . &>/dev/null && GREP_PCRE_OPT='-P'
command lsof +fg -h     &>/dev/null && LSOF_FLAG_OPT='+fg'
SSH_FAST_CIPHERS='arcfour,arcfour128,arcfour256,blowfish-cbc'
GC_VARS GNU_COLOR_OPT GREP_PCRE_OPT LSOF_FLAG_OPT SSH_FAST_CIPHERS

# Pager
LESS_ARY=(
    --force                             # Force open non-regular files
    --clear-screen                      # Print buffer from top of screen
    --dumb                              # Don't complain about terminfo errors
    --ignore-case                       # Like vim ignorecase + smartcase
    --no-lessopen                       # Ignore LESSOPEN preprocessor
    --long-prompt                       # Show position percentage
    --RAW-CONTROL-CHARS                 # Only interpret SGR escape sequences
    --chop-long-lines                   # Disable soft wrapping
    --no-init                           # Prevent use of alternate screen
    --tilde                             # Do not show nonextant lines as `~`
    --shift 8                           # Horizontal movement in columns
); GC_VARS LESS_ARY
export LESS="${LESS_ARY[@]}"
export LESSSECURE='1'                   # More secure
export LESSHISTFILE='-'                 # No ~/.lesshst
export LESS_TERMCAP_md=$'\033[37m'      # Begin bold
export LESS_TERMCAP_so=$'\033[36m'      # Begin standout-mode
export LESS_TERMCAP_us=$'\033[4;35m'    # Begin underline
export LESS_TERMCAP_mb=$'\033[5m'       # Begin blink
export LESS_TERMCAP_se=$'\033[0m'       # End standout-mode
export LESS_TERMCAP_ue=$'\033[0m'       # End underline
export LESS_TERMCAP_me=$'\033[0m'       # End mode
export PAGER='less'                     # Should be a single word to avoid quoting problems

# Ruby
export BUNDLE_PATH="$HOME/.bundle"
if [[ "$SSH_TTY" ]]; then
    export RAILS_ENV='production'  RACK_ENV='production'
else
    export RAILS_ENV='development' RACK_ENV='development'
fi

# Node.js
if [[ -d /opt/doctorjs/lib/jsctags && $NODE_PATH != */opt/doctorjs/lib/jsctags* ]]; then
    export NODE_PATH="/opt/doctorjs/lib/jsctags${NODE_PATH}"
fi

# OS X
if __OSX__; then
    # Prefer not copying Apple doubles and extended attributes
    export COPYFILE_DISABLE=1
    export COPY_EXTENDED_ATTRIBUTES_DISABLE=1
fi


### Meta Utility Functions {{{1

# List all defined functions
showfunctions() { set | grep '^[^ ]* ()'; }

# Return absolute path
# Param: $1 Filename
expand_path() { ruby -e 'print File.expand_path(ARGV.first)' "$1"; }

# Param: $1       PATH-style envvar name
# Param: [${@:2}] List of directories to prepend
__prepend_path__() {
    local var="$1"

    if (($# == 1)); then
        ruby -e 'puts "%s=%s" % [ARGV[0], ENV[ARGV[0]]]' "$var"
        return
    fi

    local dir path="$(eval "echo \$$var")" newpath
    for dir in "${@:2}"; do
        if newpath="$(ruby -e '
            paths = ARGV[0].split ":"
            dir   = File.expand_path ARGV[1]
            abort unless File.directory? dir
            puts paths.reject { |d| d == dir }.unshift(dir).join(":")
        ' "$path" "$dir")"; then
            path="$newpath"
            export "$var=$path"
            echo "$var=$path"
        fi
    done
}

# Toggle PS1 transformations
# Param: $* Interior of bash parameter expansion: '/\\u/\\u is a luser'
__ps1toggle__() {
    # Seed PS1 stack variable if unset
    declare -p __ps1stack__ &>/dev/null || __ps1stack__=("$PS1")

    # Check for existing transformation
    local idx count=${#__ps1stack__[@]} exists
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


### Directories and Init scripts {{{1

CD_FUNC -n ..           ..
CD_FUNC -n ...          ../..
CD_FUNC -n ....         ../../..
CD_FUNC -n .....        ../../../..
CD_FUNC -n ......       ../../../../..
CD_FUNC -n .......      ../../../../../..
CD_FUNC cdetc           /etc
CD_FUNC cdrcd           /etc/rc.d /usr/local/etc/rc.d
CD_FUNC cdopt           /opt
CD_FUNC cdbrew          /opt/brew
CD_FUNC cddnsmasq       /opt/dnsmasq/etc
CD_FUNC cdnginx         /opt/nginx/etc /usr/local/etc/nginx
CD_FUNC cdtmp           /tmp
CD_FUNC cdTMP           "$TMPDIR" /tmp
CD_FUNC cdvar           /var
CD_FUNC cdwww           /srv/http /srv/www ~/Sites
CD_FUNC cdapi           "$cdwww/api" && export cdapi # Export for `genapi`
CD_FUNC cdlocal         /usr/local
CD_FUNC cdhome          ~
CD_FUNC cdclojure       ~/.clojure /opt/clojure
CD_FUNC cdhaus          ~/.haus /opt/haus && export cdhaus RUBYLIB="$cdhaus/lib/ruby"
CD_FUNC cdpass          ~/.password-store
CD_FUNC cdsrc           ~/src ~guns/src /usr/local/src
CD_FUNC cdvimfiles      "$cdsrc/vimfiles"
CD_FUNC cdmetasploit    "$cdsrc/metasploit" && export cdmetasploit # Export for vim autocmd
CD_FUNC cddownloads     ~/Downloads
CD_FUNC cdmail          ~/Mail

RC_FUNC rcd             /etc/{rc,init}.d /usr/local/etc/{rc,init}.d


### Bash builtins and Haus commands {{{1

ALIAS comp='complete -p'
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

# PATH prefixer
path() { __prepend_path__ PATH "$@"; }

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
        HISTFILE="${HISTFILE_DISABLED:=$HOME/.bash_history}"
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


### Files, Disks, and Memory {{{1

# grep
ALIAS g="grep -i $GREP_PCRE_OPT $GNU_COLOR_OPT" \
      gw='g -w' \
      gv='g -v'
alias wcl='grep -c .'

# ack
ALIAS acki='ack -i' \
      ackq='ack -Q' \
      ackiq='ack -iQ'

# cat less tail
alias c='cat'
ALIAS l='less' \
      L='l +S' \
      lf='l +F' \
      lfsystem='lf /var/log/system.log' \
      lfeverything='lf /var/log/everything.log' && pager() { less -+c --quit-if-one-screen "$@"; }
ALIAS tf='tail -f' \
      tfsystem='tf /var/log/system.log' \
      tfeverything='tf /var/log/everything.log'

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
if __OSX__; then
    alias ls@='ls -@'
    alias lse='ls -e'
fi
alias lsb='lsblk -a'
if [[ -d /dev/mapper ]]; then
    alias lsmapper='ls /dev/mapper'
fi
# Param: $1 Directory to list
# Param: $2 Interior of Ruby block with filename `f`
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
lsl() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "link"'; }
lsx() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "file" and File.executable? f'; }
lsdir() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "directory"'; }

# hexdump strings hexfiend
ALIAS hex='hexdump -C'         && hexl()     { hexdump -C "$@" | pager; }
ALIAS strings='strings -t x -' && lstrings() { strings -t x - "$@" | pager; }
HAVE '/Applications/Hex Fiend.app/Contents/MacOS/Hex Fiend' && {
    alias hexfiend='open -a "/Applications/Hex Fiend.app"'
}

# find
# Param: [$1] Directory to search, if extant
# Param: [$@] Options to find
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
}; TCOMP find f
f1() { f "$@" -maxdepth 1; };               TCOMP find f1
ff() { f "$@" \( -type f -o -type l \); };  TCOMP find ff
fd() { f "$@" -type d; };                   TCOMP find fd
fl() { f "$@" -type l; };                   TCOMP find fl
fnewer() { f "$@" -newer /tmp/timestamp; }; TCOMP find fnewer
stamp() { run touch /tmp/timestamp; }
cdf() {
    cd "$(f "$@" -type d -print0 | ruby -e 'print $stdin.gets("\0") || "."' 2>/dev/null)"
}; TCOMP find cdf

# cp mv
alias cp='cp -v'
alias cpr='cp -r'
alias mv='mv -v'
swap-files() {
    ruby -r fileutils -r tempfile -e "
        include FileUtils::Verbose

        abort 'Usage: $FUNCNAME f1 f2' unless ARGV.size == 2
        ARGV.each { |f| raise %Q(No permissions to write #{f.inspect}) unless File.lstat(f).writable? }

        f1, f2 = ARGV
        tmp    = Tempfile.new(File.basename f1).path

        rm_f tmp
        mv   f1,  tmp
        mv   f2,  f1
        mv   tmp, f1
    " -- "$@"
}

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

# chmod chown touch
alias chmod='chmod -v'
alias chmodr='chmod -R'
alias chmodx='chmod +x'
alias chown='chown -v'
ALIAS chownr='chown -R'

# mkdir
alias mkdir='mkdir -v'
alias mkdirp='mkdir -p'

# df du
alias df='df -h'
alias du='du -h'
alias dus='du -s'
# Param: [$@] Files to list
dusort() {
    ruby -r shellwords -e '
        fs = ARGV.empty? ? Dir["*"] : ARGV
        idx, size,      = -1, fs.count
        res, pool, lock = [], [], Mutex.new
        label           = "\r%#{size.to_s.length}d/#{size}"

        # We are assuming POSIX 512 bytes per block
        ENV.delete "BLOCKSIZE"

        # Threading mostly for for user feedback.
        # Will usually be slower than a single call to `du`
        4.times do
            pool << Thread.new do
                loop do
                    i = lock.synchronize { idx += 1 }
                    break if i >= size
                    $stderr.print label % (i+1)
                    res[i] = [%x(du -s #{fs[i].shellescape})[/^\d+/].to_i * 512, fs[i]]
                end
            end
        end

        pool.each &:join
        print "\r"

        ps = res.sort_by { |s,f| s }.map do |s,f|
            case s
            when 0...2**10     then [                   s.to_s, "B", f]
            when 2**10...2**20 then [  "%d" % (s.to_f / 2**10), "K", f]
            when 2**20...2**30 then ["%.2f" % (s.to_f / 2**20), "M", f]
            else                    ["%.2f" % (s.to_f / 2**30), "G", f]
            end
        end

        fmt = "%#{ps.map { |s,u,f| s.length }.max}s %s  %s"
        ps.each { |p| puts fmt % p }
    ' "$@"
}

# mount
ALIAS mt='mount -v' \
      umt='umount -v' \
      mtext4='mt -t ext4' \
      mthfs='mt -t hfsplus'

# mkfs
HAVE mkfs.ext4 && {
    # Param: $1   Device
    # Param: [$2] Label
    mkfsext4() {
        local device="$1" label=()
        (($# == 2)) && label=(-L "$2")
        run mkfs.ext4 -j -O extent -O metadata_csum "${label[@]}" "$device"
    }
}

# tar
alias star='tar --strip-components=1'
alias gtar='tar zcv'
alias btar='tar jcv'
alias lstar='tar tvf'
# Option: -S Strip one level of directories
# Param:  $@ Arguments to `tar`
untar() {
    local opts=() f
    [[ "$1" == '-S' ]] && { opts+=(--strip-components=1); shift; }
    [[ -f "$1" ]] && f='f';
    run tar xv$f "$@" "${opts[@]}"
}
suntar() { untar --strip-components "$@"; }
guntar() { untar -z "$@"; }
buntar() { untar -j "$@"; }

# open
if __OSX__; then
    alias op='open'
fi

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
ALIAS rsync='rsync -e \"ssh -2\" --human-readable' \
      rsync-fast="rsync -e \\\"ssh -2 -c $SSH_FAST_CIPHERS\\\"" \
      rsync-mirror='rsync --archive --delete --partial --exclude=.git' \
      rsync-backup='rsync --archive --delete --partial --sparse --hard-links'

# dd
ALIAS dd3='dc3dd'  && TCOMP dd dd3
ALIAS ddc='dcfldd' && TCOMP dd ddc

# free
ALIAS free='free -m'

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
if __OSX__; then
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

# File browsers
ALIAS ranger='ranger -c' \
      rr='ranger -c'


### Processes {{{1

# kill killall
ALIAS k='kill' \
      k9='kill -9' \
      khup='kill -HUP' \
      kint='kill -INT' \
      kstop='kill -STOP' \
      kcont='kill -CONT' \
      kusr1='kill -USR1' \
      kquit='kill -QUIT'
ALIAS ka='killall -v' \
      ka9='ka -9' \
      kahup='ka -HUP' \
      kaint='ka -INT' \
      kastop='ka -STOP' \
      kacont='ka -CONT' \
      kausr1='ka -USR1' \
      kaquit='ka -QUIT'

# ps (traditional BSD / SysV flags seem to be the most portable)
alias p1='ps caxo comm'
alias psa='ps axo ucomm,pid,ppid,pgid,pcpu,pmem,state,nice,user,tt,start,command'
alias psg='psa | grep -v "grep -i" | g'
alias psgv='psa | grep -v "grep -i" | gv'
# BSD ps supports `-r` and `-m`
if ps ax -r &>/dev/null; then
    alias __psr__='psa -r'
    alias __psm__='psa -m'
# GNU/Linux ps supports `k` and `--sort`
else
    alias __psr__='psa k-pcpu'
    alias __psm__='psa k-rss'
fi
psr() { __psr__ | sed "s/\(.\{$COLUMNS\}\).*/\1/ ; $((LINES-2))q"; }
psm() { __psm__ | sed "s/\(.\{$COLUMNS\}\).*/\1/ ; $((LINES-2))q"; }
alias psrl='__psr__ | pager'
alias psml='__psm__ | pager'

# Report on interesting daemons
daemons() {
    ruby -e '
        processes = %x(ps axo ucomm).split("\n").map &:strip
        daemons   = %w[
            apache2 httpd nginx
            php-cgi php-fpm
            mysqld postgres
            named unbound dnsmasq dnscrypt-proxy
            exim sendmail
            smbd nmbd nfsd
            sshd ssh-agent
            subtle xmonad
            urxvtd
            wicd
            java
        ]

        daemons.each do |d|
            puts "#{d} is ALIVE" if processes.any? { |p| p =~ /\A#{d}/ }
        end
    '
}

# htop
HAVE htop && {
    # Satisfy ncurses hard-coded TERM names
    alias htop='envtmux htop'

    # htop writes its config file on exit
    htopsave() { (cd && exec gzip -c .htoprc > "$cdhaus/share/conf/htoprc.gz") }
    htoprestore() { (cd && exec gunzip -c "$cdhaus/share/conf/htoprc.gz" > .htoprc) }
}


### Switch User {{{1

ALIAS s='sudo' \
      root='exec sudo -Hs'
HAVE su && alias xsu='exec su' && TCOMP su xsu


### Network {{{1

if HAVE ifconfig; then
    alias ic='ifconfig'
elif HAVE ip; then
    alias ic='ip addr'
fi
ALIAS iw='iwconfig'
ALIAS arplan='arp -lan'
ALIAS netstatnr='netstat -nr'
ALIAS airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport' \
      ap='airport'
ALIAS net='netcfg'

# cURL
ALIAS get='curl -#L' \
      geto='curl -#LO'

# DNS
ALIAS digx='dig -x'
if __OSX__; then
    alias resolv='ruby -e "puts %x(scutil --dns).scan(/resolver #\d\s+nameserver\[0\]\s+:\s+[\h.]+/)"'
else
    alias resolv='cat /etc/resolv.conf'
fi

# NTP
alias ntpq='ntpd -g -q'

# netcat
HAVE nc   && TCOMP dig nc
HAVE ncat && TCOMP dig ncat

# tcpdump
HAVE tcpdump && {
    alias pcapdump='tcpdump -n -XX -r'
}

# ssh scp
ALIAS ssh='ssh -2' \
      ssh-fast="ssh -c $SSH_FAST_CIPHERS" \
      ssh-vm='ssh-fast -Y' \
      ssh-password='ssh -o \"PreferredAuthentications password\"' \
      ssh-remove-host='ssh-keygen -R'
ALIAS scp='scp -2' \
      scp-fast="scp -c $SSH_FAST_CIPHERS" \
      scpr='scp -r' \
      scpr-fast="scpr -c $SSH_FAST_CIPHERS"
HAVE ssh-proxy && TCOMP ssh ssh-proxy
HAVE ssh-shell && alias xssh-shell='exec ssh-shell'

# lsof
ALIAS lsof="lsof -Pn $LSOF_FLAG_OPT" && {
    alias lsif='lsof -i'
    alias lsifr="\lsof -Pi $LSOF_FLAG_OPT"
    alias lsifudp='lsif | grep UDP'
    alias lsiflisten='lsif | grep LISTEN'
    alias lsifconnect='lsif | grep -- "->"'
    alias lsifconnectr='lsifr | grep -- "->"'
    alias lsuf='lsof -U'
}

# nmap
HAVE nmap && {
    alias nmapsweep='run nmap -sU -sS --top-ports 50 -O -PE -PP -PM "$(getlip)/24"'
}

HAVE ngrep && {
    ngg() { run ngrep $device -l -W byline -d "$@"; }
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
            $FUNCNAME
        else
            for pref in  "${keys[@]}"; do
                printf "$pref: "
                scutil --get $pref
            done
        fi
    }
}

# Metasploit Framework
HAVE cdmetasploit && {
    # Param: [$1]     msf($1) command
    # Param: [${@:2}] Arguments to $1
    msf() {
        if (($#)); then
            local cmd="$cdmetasploit/msf$1"
            [[ -x "$cmd" ]] || cmd="$cdmetasploit/$1"
            shift
        else
            local cmd="$cdmetasploit/msfconsole"
        fi
        run "$cmd" "$@"
    }
    _msf() {
        local words="$(lsx "$cdmetasploit" | sed 's/^msf//')"
        COMPREPLY=($(compgen -W "$words" -- ${COMP_WORDS[COMP_CWORD]}));
    }; complete -F _msf msf
}

# Weechat
HAVE weechat-curses && {
    ((EUID)) && alias irc='(cd ~/.weechat && envtmux weechat-curses)'
}


### Browsers {{{1

if [[ -d /Applications/FirefoxAurora.app  ]]; then
    alias firefox-bin='/Applications/FirefoxAurora.app/Contents/MacOS/firefox-bin'
    disable-firefox-root-certificates() {
        mv -f /Applications/FirefoxAurora.app/Contents/MacOS/libnssckbi.dylib{,.disabled}
    }
fi


### Firewalls {{{1

# IPTables
HAVE iptables && {
    ALIAS iptables.sh='/etc/iptables/iptables.sh'
    iptlist() { echo -e "$(iptables -L -v $*)\n\n### IPv6 ###\n\n$(ip6tables -L -v $* 2>/dev/null)" | pager; }
    iptsave() {
        local ipt cmd
        for ipt in iptables ip6tables; do
            if type ${ipt}-save &>/dev/null; then
                echo "${ipt}-save > /etc/iptables/$ipt.rules"
                ${ipt}-save > /etc/iptables/$ipt.rules
            fi
        done
    }
}


### Editors {{{1

# Exuberant ctags
ALIAS ctagsr='ctags -R'

# Vim
HAVE vim && {
    alias vi='command vim -u NONE'
    alias vim='vim -p'
    alias vimtag='vim -t'
    alias vimlog='vim -V/tmp/vim.log'
    # Param: [$@] Arguments to `ff()`
    vimfind() {
        local files=()
        if (($#)); then
            local IFS=$'\n'
            files=($(ff "$@" 2>/dev/null))
            unset IFS
        fi

        if (( ${#files[@]} )); then
            vim -p "${files[@]}"
        else
            vim -c CtrlP
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

        (( ${#args[@]} )) && run vim -p "${args[@]}"
    }

    # vim-fugitive
    alias vimgit='vim -c Gstatus "$(git ls-files | sed 1q)"'
    # Param: [$1] File to browse
    gitv() {
        if [[ -f "$1" ]]; then
            vim -c "Gitv!" "$1"
        else
            vim -c 'Gitv' -c 'tabonly' .
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

    # Open local REPL project
    if ((EUID)); then
        vimclojure() {
            local port="${1:-2113}"
            if [[ -e project.clj ]] || cd ~/.clojure; then
                if nc -z 127.0.0.1 "$port" &>/dev/null; then
                    vim -c StartNailgunServer -c CtrlP
                else
                    local seconds=0
                    clojure --lein "trampoline vimclojure :port $port" &>/dev/null &
                    ( ( until nc -z 127.0.0.1 "$port"; do
                            if ((++seconds < 30)); then
                                sleep 1
                            else
                                notify "Nailgun failed to start."
                                return
                            fi
                        done
                        notify --audio "Nailgun listening on 127.0.0.1:$port"
                    ) &>/dev/null & ) & # Double fork notification so we don't overwrite the display
                    vim -c CtrlP
                fi
            fi
        }
    fi

    # Server / client functions
    # (be careful; vim clientserver is a huge security hole)
    if ((EUID)); then
        # Option: -w   Wait for file to close
        # Param:  [$@] Arguments to vim
        vimserver() {
            local name='editserver'
            if ((!$#)); then
                vim --servername $name
            elif [[ "$1" == -w ]]; then
                vim --servername $name --remote-tab-wait "${@:1}"
            else
                vim --servername $name --remote-tab "$@"
            fi
        }

        # Param: [$@] Arguments to vim
        vimstartuptime() {
            (sleep 3 && vimserver '.vimstartuptime' && (sleep 3 && rm -f '.vimstartuptime') &>/dev/null & ) &
            vim --servername 'editserver' --startuptime '.vimstartuptime' "$@"
        }
    fi

    # Frequently edited files
    alias vimautocommands='(cdhaus && exec vim etc/vim/local/autocommands.vim)'
    alias vimbashrc='(cdhaus && exec vim etc/bashrc)'
    alias vimcommands='(cdhaus && exec vim etc/vim/local/commands.vim)'
    alias viminputrc='(cdhaus && exec vim etc/inputrc)'
    alias viminteractivebash='(cdhaus && exec vim etc/bashrc.d/interactive.bash)'
    alias vimmappings='(cdhaus && exec vim etc/vim/local/mappings.vim)'
    alias vimmodifiers='(cdhaus && exec vim etc/vim/local/modifiers.vim)'
    alias vimnginx='(cdnginx && exec vim nginx.conf)'
    alias vimorg='vim -c Org!'
    alias vimrc='(cdhaus && exec vim etc/vimrc)'
    alias vimperatorrc='(cdhaus && exec vim etc/vimperatorrc)'
    alias vimhausrakefile='(cdhaus && exec vim Rakefile)'
    alias vimmuttrc='(cdhaus && exec vim etc/%mutt/muttrc)'
    alias vimmacsetup='(cdhaus && exec vim bin/macsetup)'
    alias vimscratch='vim -c Scratch'
    alias vimtmux='(cdhaus && exec vim etc/tmux.conf)'
    alias vimtodo='vim -c "Org! TODO"'
    alias vimunicode='(cdhaus && exec vim share/doc/unicode-table.txt.gz)'
    alias vimwm='(cdhaus && exec vim etc/%xmonad/xmonad.hs)'
    alias vimxdefaults='(cdhaus && exec vim etc/Xdefaults)'
    alias vimxinitrc='vim ~/.xinitrc'
}


### Terminal Multiplexers {{{1

# Tmux
HAVE tmux && {
    HAVE tmuxlaunch && alias xtmuxlaunch='exec tmuxlaunch'
    tmuxeval() {
        local vars=$(sed "s:^:export :g" <(tmux show-environment | grep -E "^[A-Z_]+=[a-zA-Z0-9/.-]+"))
        echo "$vars"
        eval "$vars"
    }

    envtmux() {
        run env $([[ $TERM == tmux* ]] && echo TERM=screen-256color) "$@"
    }
}

# GNU screen
HAVE screen && {
    alias screenr='screen -R'
    alias xscreenr='exec screen -R'; TCOMP screen xscreenr
}


### Compilers {{{1

# make
ALIAS mk='make' \
      mkclean='make clean' \
      mkdistclean='make distclean' \
      mkinstall='make install' \
      mkj2='make -j2' \
      mkj4='make -j4' \
      mkj8='make -j8' \
      mkj16='make -j16' && cdmkinstall() { (cd "$@"; make install) }


### SCM {{{1

# diff patch
ALIAS di='diff -U3' \
      diw='di -w' \
      dir='di -r' \
      diq='di -q' \
      dirq='di -rq'
ALIAS patch='patch --version-control never'

# git
HAVE git && {
    # Slightly shorter versions of git commands
    for _git_alias in $(git config --list | sed -ne 's/^alias\.\([^=]*\)=.*/\1/p'); do
        alias "git$_git_alias=git $_git_alias"
    done
    unset _git_alias

    # Github
    # Param: $1   User name
    # Param: $2   Repository name
    # Param: [$3] Branch name
    githubclone() {
        (($# == 2 || $# == 3)) || { echo "Usage: $FUNCNAME user repo [branch]"; return 1; }
        local user="$1" repo="$2" branch
        [[ $3 ]] && branch="--branch $3"
        run git clone $branch "https://github.com/$user/$repo"
    }

    # PS1 git status
    REQUIRE ~/.bashrc.d/git-prompt.sh
    gitps1() {
        __ps1toggle__ '/\\w/\\w\$(__git_ps1 " → \[\033[3m\]%s\[\033[23m\]")'
    }; gitps1
}
githubget() {
    (($# == 2 || $# == 3)) || { echo "Usage: $FUNCNAME user repo [branch]"; return 1; }
    local user="$1" repo="$2" branch="${3:-master}"
    run curl -#L "https://github.com/$user/$repo/tarball/$branch"
}


### Ruby {{{1

type ruby &>/dev/null && {
    # Ruby versions
    # Param: $1 Alias suffix
    # Param: $2 Ruby bin directory
    RUBY_VERSION_SETUP() {
        local suf="$1" bin="$2"
        ALIAS "ruby${suf}=${bin}/ruby" && {
            alias "rb${suf}=${bin}/ruby"
            alias "rb${suf}e=${bin}/ruby -e"

            CD_FUNC -f "cdruby${suf}" "ruby${suf} -r mkmf -e \"puts RbConfig::CONFIG['rubylibdir']\""
            CD_FUNC -f "cdgems${suf}" "ruby${suf} -rubygems -e \"puts File.join(Gem.dir, 'gems')\""

            # Rubygems package manager
            ALIAS "gem${suf}=${bin}/gem" && {
               # alias geme
               alias "gem${suf}g=run ${bin}/gem list | g"
               alias "gem${suf}i=run ${bin}/gem install"
               alias "gem${suf}q=run ${bin}/gem specification -r"
               alias "gem${suf}s=run ${bin}/gem search -r"
               alias "gem${suf}u=run ${bin}/gem uninstall"
               # alias gemsync
               alias "gem${suf}outdated=run ${bin}/gem outdated"
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
        RUBY_VERSION_SETUP ''  "$(dirname "$(type -P ruby)")"
    fi
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

    # Create a private build of a gem
    gem-private-build() {
        ruby -rubygems -r fileutils -e "
            abort 'Usage: $FUNCNAME spec suffix [outdir]' unless (2..3) === ARGV.size

            specfile, suffix, outdir = ARGV
            spec = Gem::Specification.load specfile
            spec.version = '%s.%s' % [spec.version, suffix]
            gem = Gem::Builder.new(spec).build
            FileUtils.mv gem, outdir if outdir
        " "$@"
    }

    # Local api server @ `$cdapi`
    HAVE cdapi && {
        # Param: $@ API Site names
        api() { local d; for d in "$@"; do chrome "http://${cdapi##*/}/$d"; done; }
        _api() {
            COMPREPLY=($(compgen -W "$(lsd "$cdapi")" -- ${COMP_WORDS[COMP_CWORD]}));
        }; complete -F _api api
    }
}


### Python {{{1

ALIAS py='python'


### JVM {{{1

# Leiningen, Clojure package manager
HAVE lein && {
    # alias leine=
    # alias leing=
    alias leini='run lein install'
    # alias leinq=
    alias leins='run lein search'
    # alias leinu=
    # alias leinsync=
    # alias leinoutdated=
}

ALIAS java-share-dump='java -server -Xshare:dump'
ALIAS ngstop='ng ng-stop'


### JavaScript {{{1

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


### Perl {{{1

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
        ' "$@"
    }
}


### Haskell {{{1

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


### Databases {{{1

ALIAS mysql='mysql -p' \
      mysqldump='mysqldump -p' \
      mysqladmin='mysqladmin -p'

ALIAS ppsql='psql postgres'

ALIAS sqlite='sqlite3' && {
    # Param: $1 SQLite db
    sqliteschema() {
        {   sqlite3 "$1" <<< .schema
            local t tables=($(sqlite3 "$1" <<< .table))
            for t in "${tables[@]}"; do
                echo -e "\n$t:"
                local q1="SELECT * FROM $t ORDER BY id DESC LIMIT 1;"
                local q2="SELECT * FROM $t LIMIT 1;"
                local sql="$(sqlite3 "$1" <<< "$q1")"
                if [[ "$sql" =~ "SQL error near line 1: no such column: id" ]]; then
                    local sql="$(sqlite3 "$1" <<< "$q2")"
                fi
                echo "$sql"
            done
        } 2>/dev/null | pager
    }
}


### Hardware control {{{1

if __OSX__; then
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

HAVE batterystat && {
    alias logbatterystat='batterystat --json >> ~/Documents/Notes/batterystat.json'
}

HAVE wpa_supplicant wpa_passphrase && {
    wpajoin() {
        local OPTIND OPTARG opt iface='wlan0'
        while getopts :i opt; do
            case $opt in
                i) iface="$OPTARG";;
                *) echo "USAGE: $FUNCNAME [-i iface] essid [password]"; return 1
            esac
        done
        shift $((OPTIND-1))
        local ssid="$1"; [[ $ssid ]] || ssid=$(printf "ssid: " >&2; read r; echo "$r")
        local pass="$2"; [[ $pass ]] || pass=$(printf "pass: " >&2; read r; echo "$r")
        wpa_supplicant -i "$iface" -c <(wpa_passphrase "$ssid" "$pass")
    }
}


### Encryption {{{1

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
ALIAS gpg='gpg --no-encrypt-to'

HAVE cryptsetup cs && TCOMP cryptsetup cs
ALIAS dx='dumpcert exec --'

if __OSX__; then
    alias list-keychains='find {~,,/System}/Library/Keychains -type f -maxdepth 1'
    alias security-dump-certificates='run security export -t certs'
fi


### Virtual Machines {{{1

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


### Package Managers {{{1

if __OSX__; then
    # MacPorts package manager
    ALIAS port='port -c' && {
        porte() { local fs=() f; for f in "$@"; do fs+=("$(port file "$f")"); done; vim "${fs[@]}"; }
        alias portg='run port -c installed | g'
        alias porti='run port -c install'
        alias portq='run port -c info'
        alias ports='run port -c search'
        alias portu='run port -c uninstall'
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
        alias brewu='run brew uninstall'
        alias brewsync='run sh -c "cd \"$(brew --prefix)\" && git checkout master && git pull && \
                                   git checkout guns && git merge master -m "Merge master into guns" && git push github --all"'
        alias brewoutdated='brew outdated'

        alias brewprefix='brew --prefix'
    }
elif __LINUX__; then
    # Aptitude package manager
    ALIAS apt='aptitude' && {
        apte() { vim -p "$(apt-file "$@")"; }
        alias aptg='run aptitude search ~i | g'
        alias apti='run aptitude install'
        alias aptq='run aptitude show'
        alias apts='run aptitude search'
        alias aptu='run aptitude remove'
        alias aptsync='run aptitude update'
        # alias aptoutdated
    }

    # Pacman package manager
    ALIAS pac='pacman' && {
        # alias pace
        alias pacg='run pacman -Qs'
        alias paci='run pacman -S'
        alias pacq='run pacman -Si'
        alias pacs='run pacman -Ss'
        alias pacu='run pacman -R'
        alias pacsync='run pacman -Sy'
        alias pacoutdated='run pacman -Qu'
    }
fi


### Media {{{1

# Imagemagick
ALIAS geometry='identify -format "%w %h"'

# feh
HAVE feh && {
    fehbg() { feh --bg-fill "$(expand_path "$1")"; }
    fshow() { feh --recursive "${@:-.}"; }
    frand() { feh --recursive --randomize "${@:-.}"; }
    ftime() {
        ruby -r set -e '
            args = ARGV.empty? ? ["."] : ARGV
            fs = args.reduce Set.new do |set, arg|
                set.merge Dir[File.join(arg, "*")].reject { |f| File.directory? f }
            end
            exec "feh", *fs.sort_by { |f| File.mtime f }.reverse
        ' -- "$@"
    }
}

# cmus
HAVE cmus && {
    alias cmus='envtmux cmus'
}

# espeak
HAVE espeak && ! HAVE say && say() { espeak -ven-us "$*"; }

# VLC
[[ -x /Applications/VLC.app/Contents/MacOS/VLC ]] && {
    alias vlc='open -a /Applications/VLC.app'
}

# Quick Look (OS X)
HAVE qlmanage && alias ql='qlmanage -p'


### X {{{1

HAVE startx && alias xstartx='exec startx'

# Clipboard
ALIAS xselb='xsel -b'

# Subtle WM
ALIAS subtlecheck='subtle --check'

# Xmonad
HAVE xmonad && xmonadrecompile() {
    if ! ps axo ucomm | grep '^ghc' &>/dev/null; then
        { run xmonad --recompile && run xmonad --restart && notify --audio; } || notify 'Xmonad compile failure'
    else
        notify 'GHC seems to be busy'
    fi
}


### Linux Console {{{1

if [[ "$TERM" == linux ]]; then
    alias vconsole-setup="loadkeys \"$cdhaus/share/kbd/macbook.map.gz\"; unicode_start"
fi


### systemd {{{1

ALIAS sd='systemd' \
      sc='systemctl'


### Launchd {{{1

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


### GUI programs {{{1

if __OSX__; then
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

: # Return true
