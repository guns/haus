### BASH FUNCTIONS, ALIASES, and VARIABLES ###

# Requires ~/.bashrc.d/functions.bash

### Environment Variables {{{1

# Bash history
export HISTIGNORE='&:cd:.+(.):ls:lc: *' # Ignore dups, common commands, and leading spaces

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
command ls --color ~ &>/dev/null && export GNU_COLOR_OPT='--color'
grep -P . <<< . &>/dev/null      && export GREP_PCRE_OPT='-P'

# Pager
LESS_ARY=(
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
); GC_VARS LESSARY
export LESS="${LESS_ARY[@]}"
export LESSSECURE=1                     # ++secure
export LESSHISTFILE='-'                 # No ~/.lesshst
export LESS_TERMCAP_md=$'\e[37m'        # Begin bold
export LESS_TERMCAP_so=$'\e[36m'        # Begin standout-mode
export LESS_TERMCAP_us=$'\e[4;35m'      # Begin underline
export LESS_TERMCAP_mb=$'\e[5m'         # Begin blink
export LESS_TERMCAP_se=$'\e[0m'         # End standout-mode
export LESS_TERMCAP_ue=$'\e[0m'         # End underline
export LESS_TERMCAP_me=$'\e[0m'         # End mode
export PAGER='less'                     # Should be a single word to avoid quoting problems

# Ruby
export BUNDLE_PATH="$HOME/.bundle"
if [[ "$SSH_TTY" ]]; then
    export RAILS_ENV='production' RACK_ENV='production'
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

# Transfer completions
# Param: $1 Source command
# Param: $2 Target command
tcomp() { eval $({ complete -p "$1" || echo :; } 2>/dev/null) "$2"; }

# Chop lines to $COLUMNS
choplines() { ruby -pe "\$_.sub! /^(.{$COLUMNS}).*/, '\1'"; }

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
CD_FUNC cddnsmasq       /opt/dnsmasq/etc /usr/local/etc
CD_FUNC cdnginx         /opt/nginx/etc /usr/local/etc/nginx
CD_FUNC cdtmp           /tmp
CD_FUNC cdvar           /var
CD_FUNC cdwww           /srv/http /srv/www ~/Sites
CD_FUNC cdapi           "$cdwww/api" && export cdapi # Export for `genapi`
CD_FUNC cdlocal         /usr/local
CD_FUNC cdhaus          ~/.haus /opt/haus
CD_FUNC cdsrc           ~/src /usr/local/src
CD_FUNC cdmetasploit    "$cdsrc/metasploit" && export cdmetasploit # Export for vim autocmd
CD_FUNC cddownloads     ~/Downloads
CD_FUNC cdappsupport    ~/Library/Application\ Support
CD_FUNC cdprefs         ~/Library/Preferences

RC_FUNC rcd             /etc/rc.d /usr/local/etc/rc.d
RC_FUNC initd           /etc/init.d /usr/local/etc/init.d


### Bash builtins and Haus commands {{{1

ALIAS comp='complete -p'
ALIAS cv='command -v'
alias d='dirs'
alias h='history'
ALIAS j='jobs'
alias o='echo'
alias p='pushd .'
alias pp='popd'
alias rehash='hash -r'
alias rmhist='rm -f ~/.bash_history ~/.viminfo && unset HISTFILE && exec $SHELL'
t() { type "$@"; }; tcomp type t
ALIAS ta='t -a' \
      tp='t -P'
ALIAS x='exec'
alias wrld='while read l; do'; tcomp exec wrld

# PATH prefixer
path() { __prepend_path__ PATH "$@"; }

# Toggle xtrace mode
setx() {
    if [[ "$SHELLOPTS" =~ :?xtrace:? ]]; then
        set +x
    else
        set -x
    fi
}

# Toggle history
nohist() {
    if [[ "$SHELLOPTS" =~ :?history:? ]]; then
        set +o history
    else
        set -o history
    fi
    __ps1toggle__ '/\\w/\\w [nohist]'
}

# report remind
ALIAS r='report'

# run bgrun
HAVE run   && tcomp exec run
HAVE bgrun && tcomp exec bgrun

# Simple fs event loop for execution in current shell
alias watch='while read path <<< "$(ruby -r fssm -e "
    FSSM.monitor Dir.pwd, %q{**/*} do
        create { |base, path| puts %Q{\e[1;32m++\e[0m #{path}}; raise Interrupt }
        update { |base, path| puts %Q{\e[1;34m::\e[0m #{path}}; raise Interrupt }
        delete { |base, path| puts %Q{\e[1;31m--\e[0m #{path}}; raise Interrupt }
    end
" 2>/dev/null)" && echo -e "$path";' # do ...; done


### Files, Disks, and Memory {{{1

# grep
alias g="grep -i $GREP_PCRE_OPT $GNU_COLOR_OPT"
alias g3='g -C3'
alias gv='g -v'
alias wcl='grep -c .'

# ack
ALIAS acki='ack -i'

# cat less tail
alias c='cat'
alias l='less'
alias L='l +S' # Soft-wrap
alias lf='l +F' # Follow-forever
ALIAS tf='tail -f'
# Logfiles
if [[ -r /var/log/system.log ]]; then
    ALIAS tfsystem='tf /var/log/system.log'
    alias lfsystem='lf /var/log/system.log'
fi
if [[ -r /var/log/everything.log ]]; then
    ALIAS tfeverything='tf /var/log/everything.log'
    alias lfeverything='lf /var/log/everything.log'
fi
# An eager-to-exit `less`
pager() { less -+c --quit-if-one-screen "$@"; }

# ls
alias ls="ls -Ahl $GNU_COLOR_OPT"
alias lc='ls -C'
alias lsr='ls -R'; lsrl() { ls -R "${@:-.}" | pager; }
alias lst='ls -t'; lstl() { ls -t "${@:-.}" | pager; }
alias l1='command ls -1'
alias l1g='l1 | g'
alias lsg='ls | g'
if __OSX__; then
    alias ls@='ls -@'
    alias lse='ls -e'
fi
if [[ -d /dev/disk ]]; then
    alias lsid='ls /dev/disk/by-id/'
    alias lslabel='ls /dev/disk/by-label'
    alias lspath='ls /dev/disk/by-path'
    alias lsuuid='ls /dev/disk/by-uuid'
fi
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
lsd() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "directory"'; }
lsl() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "link"'; }
lsx() { __lstype__ "${1:-.}" 'File.lstat(f).ftype == "file" and File.executable? f'; }

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
}; tcomp find f
f1() { f "$@" -maxdepth 1; };               tcomp find f1
ff() { f "$@" \( -type f -o -type l \); };  tcomp find ff
fd() { f "$@" -type d; };                   tcomp find fd
fl() { f "$@" -type l; };                   tcomp find fl
stamp() { run touch /tmp/timestamp; }
fnewer() { f "$@" -newer /tmp/timestamp; }; tcomp find fnewer
cdf() {
    cd "$(f "$@" -type d -print0 | ruby -e 'print $stdin.gets("\0") || "."' 2>/dev/null)"
}; tcomp find cdf

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
    " "$@"
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
    echo >&2 'Calculating sorted file size...'

    local buf f line

    if (($#)); then
        buf="$(for f in "$@"; do du -s "$f"; done)"
    else
        buf="$(f1 \( ! -name . \) -print0 | xargs -0 du -s)"
    fi

    echo -e "$buf" | sort -n | cut -f2 | while read line; do
        command du -sh -- "$line"
    done
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
        run mkfs.ext4 -j -O extent "${label[@]}" "$device"
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
suntar() { untar -S "$@"; }
zuntar() { untar -z "$@"; }

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
        " "$@"
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
    alias hdetach='hdiutil detach'
    alias hmount='hdiutil mount'
    alias hcompact='hdiutil compact'
    alias hresize='hdiutil resize'
    # Param: $1 Size specification
    # Param: $2 Name of file and volume
    hcreate() {
        (($# == 2)) || { echo >&2 "Usage: $FUNCNAME size name"; return 1; }

        local size="$1" name="$2"
        run hdiutil create \
                    -size "$size" \
                    -fs HFS+J \
                    -encryption AES-128 \
                    -volname "${name##*/}" \
                    "$name"
    }

    # http://osxdaily.com/2007/03/23/create-a-ram-disk-in-mac-os-x/
    # Param: $1 Size specification
    # Param: $2 Volume name
    ramdisk() {
        (($# == 2)) || { echo "Usage: $FUNCNAME size name"; return 1; }

        local size="$1" name="$2"
        local disk="$(run hdiutil attach -nomount ram://$(ruby -e '
            puts ARGV.first.scan(/([\d\.]+)(\D*)/).inject(0) { |sum, (num, unit)|
                sum + case unit
                when /\Ag\z/i    then num.to_f * 2**30
                when /\Am\z/i,"" then num.to_f * 2**20
                when /\Ak\z/i    then num.to_f * 2**10
                else 0
                end
            }.round / 512
        ' "$size"))"

        # Just make sure that $disk isn't a currently mounted volume
        if ! mount | awk '{print $1}' | grep -q "$disk"; then
            run diskutil eraseVolume HFS+ "$name" $disk # unquoted!
        fi
    }
}

# rsync
ALIAS rsync='rsync --human-readable' \
      rsync-mirror='rsync --archive --delete --partial --exclude=.git' \
      rsync-backup='rsync --archive --delete --partial --sparse --hard-links' && {
    if __OSX__; then
        alias applersync='/usr/bin/rsync --human-readable --progress --extended-attributes'
        tcomp rsync applersync
        ALIAS applersync-mirror='applersync --archive --delete --partial --exclude=.git'
        ALIAS applersync-backup='applersync --archive --delete --partial --sparse --hard-links'
    fi
}

# dd
ALIAS dd3='dc3dd'  && tcomp dd dd3
ALIAS ddc='dcfldd' && tcomp dd ddc

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
ALIAS rr='ranger'


### Processes {{{1

# kill killall
ALIAS k='kill' \
      k9='kill -9' \
      khup='kill -HUP' \
      kint='kill -INT' \
      kusr1='kill -USR1' \
      kquit='kill -QUIT'
ALIAS ka='killall -v' \
      ka9='ka -9' \
      kahup='ka -HUP' \
      kaint='ka -INT' \
      kausr1='ka -USR1' \
      kaquit='ka -QUIT'

# ps (traditional BSD / SysV flags seem to be the most portable)
alias p1='ps caxo comm'
alias psa='ps axo ucomm,pid,ppid,pgid,pcpu,pmem,state,nice,user,tt,start,command'
alias psg='psa | grep -v "grep -i" | g'
# BSD ps supports `-r` and `-m`
if ps ax -r &>/dev/null; then
    alias __psr__='psa -r'
    alias __psm__='psa -m'
# GNU/Linux ps supports `k` and `--sort`
else
    alias __psr__='psa k-pcpu'
    alias __psm__='psa k-rss'
fi
psr() { __psr__ | choplines | sed "$((LINES-2))q"; }
psm() { __psm__ | choplines | sed "$((LINES-2))q"; }
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
            named unbound dnsmasq
            exim sendmail
            smbd nmbd nfsd
            sshd
            urxvtd
            wicd
        ]

        daemons.each do |d|
            puts "#{d} is ALIVE" if processes.any? { |p| p =~ /\A#{d}/ }
        end
    '
}

# htop
HAVE htop && [[ -d "$cdhaus/share/conf" ]] && {
    # htop writes its config file on exit
    htopsave() { (cd && exec gzip -c .htoprc > "$cdhaus/share/conf/htoprc.gz") }
    htoprestore() { (cd && exec gunzip -c "$cdhaus/share/conf/htoprc.gz" > .htoprc) }
}


### Switch User {{{1

ALIAS s='sudo' \
      root='exec sudo su'
HAVE su && {
    alias xsu='exec su'
    tcomp su xsu
}


### Network {{{1

ALIAS ic='ifconfig'
ALIAS iw='iwconfig'
ALIAS arplan='arp -lan'
ALIAS netstatnr='netstat -nr'
ALIAS airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport' \
      ap='airport'

# cURL
ALIAS get='curl -#L' \
      geto='curl -#LO'

# DNS
ALIAS digx='dig -x'
alias resolv='cat /etc/resolv.conf'
if __OSX__; then
    alias flushdns='run dscacheutil -flushcache'
fi

# netcat
HAVE nc   && tcomp host nc
HAVE ncat && tcomp host ncat

# ssh scp
# http://blog.urfix.com/25-ssh-commands-tricks/
ALIAS ssh='ssh -C -2' \
      sshx='ssh -Y' \
      ssh-master='ssh -Nn -M' \
      ssh-tunnel='ssh -Nn -M -D 22222' \
      ssh-password='ssh -o \"PreferredAuthentications password\"' \
      ssh-nocompression='ssh -o "Compression no"'
ALIAS scp='scp -C -2' \
      scpr='scp -r'
HAVE ssh-agent && {
    alias ssh-shell="[[ \"\$SSH_AGENT_PID\" ]] || exec ssh-agent \"$SHELL\""
    HAVE sudo && alias rootssh-shell="[[ \"\$SSH_AGENT_PID\" ]] || exec sudo ssh-agent \"$SHELL\""
}
HAVE ssh-proxy && tcomp ssh ssh-proxy

# lsof
ALIAS lsof='lsof -Pn +fg' && {
    alias lsif='lsof -i'
    alias lsifudp='lsif | grep UDP'
    alias lsiflisten='lsif | grep LISTEN'
    alias lsifconnect='lsif | grep -- "->"'
    alias lsuf='lsof -U'
}

# nmap
ALIAS nmapscan='nmap -sS -A' && {
    nmapsweep() { run nmap -sP -PPERM $(getlip)/24; }
}

# networksetup
HAVE networksetup && {
    # Param: [$*] New hostname
    computername() {
        if (($#)); then
            networksetup -setcomputername "$*"
            hostname "$*"
            $FUNCNAME
        else
            echo "computername: $(networksetup -getcomputername)"
            echo "hostname:     $(hostname)"
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
    ((EUID)) && alias irc='weechat-curses'
    alias ircedit='(cd ~guns/.weechat && exec vim weechat.conf)'
}

# OS X Sync
ALIAS resetsync.pl='/System/Library/Frameworks/SyncServices.framework/Resources/resetsync.pl'


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
ALIAS ctags='ctags -f .tags' \
      ctagsr='ctags -R'

# Vim
HAVE vim && {
    alias v='command vim'
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
            vim -c 'CommandT'
        fi
    }; tcomp find vimfind

    # Vim-ManPage
    alias mman='command man'
    tcomp man mman
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
    alias vimgit='vim -c Gstatus .'
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
            (sleep 3 && vimserver '.vimstartuptime' && (sleep 3 && rm -f '.vimstartuptime') & ) &
            vim --servername 'editserver' --startuptime '.vimstartuptime' "$@"
        }
    fi

    # frequently edited files
    alias vimabbreviations='(cdhaus && exec vim etc/vim/local/abbreviations.vim)'
    alias vimautocommands='(cdhaus && exec vim etc/vim/local/autocommands.vim)'
    alias vimbashrc='(cdhaus && exec vim etc/bashrc)'
    alias vimcommands='(cdhaus && exec vim etc/vim/local/commands.vim)'
    alias viminputrc='(cdhaus && exec vim etc/inputrc)'
    alias vimlocalbash='(cdhaus && exec vim etc/bashrc.d/local.bash)'
    alias vimmappings='(cdhaus && exec vim etc/vim/local/mappings.vim)'
    alias vimnginx='(cdnginx && exec vim nginx.conf)'
    alias vimorg='vim -c Org!'
    alias vimrc='(cdhaus && exec vim etc/vimrc)'
    alias vimrcconf='(cd /etc && vim rc.conf)'
    alias vimscratch='vim -c Scratch'
    alias vimsubtle='(cdhaus && vim etc/%config/subtle/subtle.rb)'
    alias vimtodo='vim -c "Org! TODO"'
}


### Terminal Multiplexers {{{1

# Tmux
HAVE tmux tmuxlaunch && alias xtmuxlaunch='exec tmuxlaunch'

# GNU screen
HAVE screen && {
    alias screenr='screen -R'
    alias xscreenr='exec screen -R'
    tcomp screen xscreenr
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
      mkj16='make -j16'


### SCM {{{1

# diff patch
ALIAS diff='diff -U3' \
      diffw='diff -w' \
      diffr='diff -r' \
      diffq='diff -q' \
      diffrq='diff -rq'
ALIAS patch='patch --version-control never'

# git
HAVE git && {
    # Slightly shorter versions of git commands
    for A in $(git config --list | sed -ne 's/^alias\.\([^=]*\)=.*/\1/p'); do
        alias "git$A=git $A"
    done
    GC_VARS A

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
    HAVE __git_ps1 && {
        gitps1() {
            __ps1toggle__ '/\\w/\\w\$(__git_ps1 " → \[\e[3m\]%s\[\e[23m\]")'
        }; gitps1 # Turn it on now!
    }
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

            # Core ruby programs
            if [[ "$suf" == 18* ]]; then
                ALIAS "irb${suf}=${bin}/irb -Ku"
            else
                ALIAS "irb${suf}=${bin}/irb"
            fi
            ALIAS "ri${suf}=${bin}/ri"
            ALIAS "rake${suf}=${bin}/rake" \
                  "rk${suf}=rake${suf}" \
                  "rk${suf}t=rake${suf} -T"

            # Useful gem executables
            ALIAS "sdoc${suf}=${bin}/sdoc"
            ALIAS "bundle${suf}=${bin}/bundle"
            HAVE "${bin}/rdebug" && {
                ALIAS "rdb${suf}=${bin}/rdebug" \
                      "rdb${suf}c=${bin}/rdebug -c"
                tcomp exec "rdebug${suf}"
            }
        }
    }; GC_FUNC RUBY_VERSION_SETUP

    RUBY_VERSION_SETUP ''  "$(dirname "$(type -P ruby)")"
    RUBY_VERSION_SETUP 19  /opt/ruby/1.9/bin
    RUBY_VERSION_SETUP 18  /opt/ruby/1.8/bin
    RUBY_VERSION_SETUP 186 /opt/ruby/1.8.6/bin

    # PATH variables
    rubylib() { __prepend_path__ RUBYLIB "$@"; }
    gempath() { path "${@:-.}/bin"; rubylib "${@:-.}/lib"; }

    # Rails
    ALIAS ra='rails'

    # SDoc isn't quite Ruby 1.9 compatible
    HAVE genapi ruby18 && {
        # Param: $@ Arguments to `genapi`
        genapi() { /opt/ruby/1.8/bin/ruby -KU "$(type -P genapi)" "$@"; }
    }

    # Local api server @ `$cdapi`
    HAVE cdapi && {
        # Param: $@ API Site names
        api() { local d; for d in "$@"; do chrome "http://${cdapi##*/}/$d"; done; }
        _api() {
            local words="$(lsd "$cdapi")"
            COMPREPLY=($(compgen -W "$words" -- ${COMP_WORDS[COMP_CWORD]}));
        }; complete -F _api api
    }
}


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
      perlpie='perl -i -pe'


### Haskell {{{1

# cabal package manager
HAVE cabal && {
    # alias cabale
    alias cabalg='run cabal list installed'
    alias cabali='run cabal install --global'
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

HAVE sqlite3 && {
    # Param: $1 SQLite db
    sqlite3schema() {
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
            run command pmset "$@"
        else
            run command pmset -g custom
        fi
    }

    # Turn off hibernate mode on Macbooks
    nohibernate() {
        local image='/var/vm/sleepimage'
        run rm -f "$image"
        run ln -s /dev/null "$image"
        pmset -a hibernatefile "$image"
        pmset -a hibernatemode 0
    }

    # Suspend idle sleep
    alias noidle='pmset noidle'
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
                *) echo "USAGE: $FUNCNAME [-i iface] essid password"; return 1
            esac
        done
        shift $((OPTIND-1))
        bgrun wpa_supplicant -i "$iface" -c <(wpa_passphrase "$@")
    }
}


### Encryption {{{1

# dm-crypt
ALIAS cs='cryptsetup' && {
    alias csopen='cryptsetup luksOpen'
    alias csclose='cryptsetup luksClose'
    alias csdump='cryptsetup luksDump'

    # Option: -c   Cipher string
    # Option: -i   Iteration time in milliseconds
    # Param:  $1   Device
    # Param:  [$2] Key file
    csformat() {
        local usage="Usage: $FUNCNAME [-c cipher] [-i iter-time] device [keyfile]"
        local opts=(--verbose) cipher='serpent-xts-plain64'

        local OPTIND OPTARG opt
        while getopts :hc:i: opt; do
            case $opt in
            c) cipher="$OPTARG";;
            i) opts+=(--iter-time "$OPTARG");;
            *) echo "$usage"; return 1
            esac
        done
        shift $((OPTIND-1))

        # Set cipher and key type
        opts+=(--cipher "$cipher")
        case $# in
        1) opts+=(--verify-passphrase --key-size 512);;
        2) opts+=(--key-file "$2");;
        *) echo "$usage"; return 1
        esac

        # Run on given device
        run cryptsetup "${opts[@]}" luksFormat "$1"
    }

    # Option: -d Debug mode
    # Option: -f Key file
    # Option: -t Filesystem type
    # Param:  $1 Device
    # Param:  $2 Mountpoint (basename is also mapper name)
    csmount() {
        local usage="Usage: $FUNCNAME [-d] [-f keyfile] [-t fstype] device mountpoint"
        local opts=(--verbose) fstype='ext4'

        local OPTIND OPTARG opt
        while getopts :df:t: opt "$@"; do
            case $opt in
            d) opts+=(--debug);;
            f) opts+=(--key-file "$OPTARG");;
            t) fstype="$OPTARG";;
            *) echo "$usage"; return 1
            esac
        done
        shift $((OPTIND-1))

        (($# == 2)) || { echo "$usage"; return 1; }
        local mapname="${2%/}"; mapname="${mapname##*/}"

        if run cryptsetup "${opts[@]}" luksOpen "$1" "$mapname"; then
            run mount -t "$fstype" "/dev/mapper/$mapname" "$2"
        fi
    }; tcomp mount csmount

    # Param: $1 Device/mountpoint (basename is also mapper name)
    csumount() {
        (($# == 1)) || { echo "Usage: $FUNCNAME mountpoint"; return 1; }
        local mapname="${1%/}"; mapname="${mapname##*/}"
        run umount "$1" && run cryptsetup luksClose "/dev/mapper/$mapname"
    }; tcomp umount csumount
}


### Virtual Machines {{{1

# VMWare
ALIAS vmrun='/Library/Application\ Support/VMware\ Fusion/vmrun' \
      vmnetstart='/Library/Application\ Support/VMware\ Fusion/boot.sh --start' \
      vmnetstop='/Library/Application\ Support/VMware\ Fusion/boot.sh --stop' \
      vmnetrestart='/Library/Application\ Support/VMware\ Fusion/boot.sh --restart' \
      vmware-vdiskmanager='/Library/Application\ Support/VMware\ Fusion/vmware-vdiskmanager'


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
        alias brewsync='run sh -c "cd \"$(brew --prefix)\" && git co master && git remote update && brew update && git co guns && git merge master"'
        alias brewoutdated='brew outdated'
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
        if [[ "$1" == -r ]]; then
            local pattern='**/*'
        else
            local pattern='*'
        fi

        local IFS=$'\n'
        local fs=($(ruby -e '
            puts Dir[ARGV.first].reject { |f| File.directory? f }.sort_by { |f| File.mtime f }.reverse
        ' "$pattern"));
        unset IFS

        feh "${fs[@]}"
    }
}

# espeak
HAVE espeak && ! HAVE say && say() { espeak -ven-us "$*"; }

# VLC
ALIAS vlc='/Applications/VLC.app/Contents/MacOS/VLC'

# iTunes
HAVE itunes-switch && {
    # Param: $1 Key name
    _itunes-switch() {
        [[ -r ~/Music/.itunes.yml ]] || return
        local words="$(awk -F: '{print $1}' < ~/Music/.itunes.yml)"
        COMPREPLY=($(compgen -W "$words" -- ${COMP_WORDS[COMP_CWORD]}))
    }; complete -F _itunes-switch itunes-switch
}


### X {{{1

HAVE startx && alias xstartx='exec startx'

HAVE xset xrdb && {
    alias xreload='run xset r rate 200 60; run xrdb ~/.Xdefaults'
}

HAVE xecho && {
    for XCMD in left center right cursor width title; do
        alias "x$XCMD=xecho $XCMD"
    done
    GC_VARS XCMD
}

# Subtle WM
ALIAS subtlecheck='subtle --check'


### Games {{{1

HAVE nethack && {
    alias nethack='env NETHACKOPTIONS="@~guns/src/nethack/etc/nethackrc" command nethack -u-u'
    alias nethackwiz="nethack -u $USER -D"
    HAVE rxvt && {
        nethackterm() {(
            cd ~guns/src/nethack/source &&
            run xset +fp ~guns/src/nethack/etc &&
            run xset fp rehash &&
            bgrun rxvt -fn vga11x19 -geometry 115x39 -fg white -cr white -title NetHack --meta8
        )}
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
            ' "$*"
        }
    }

    ALIAS screensaverengine='/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine'
fi

: # Return true
