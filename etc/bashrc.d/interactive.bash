###
### BASH FUNCTIONS, ALIASES, and VARIABLES
###

# Requires ~/.bashrc.d/functions.bash

### Environment Variables

# Bash history
export HISTSIZE='65535'
export HISTIGNORE='&:cd:.+(.):ls:lc: *' # Ignore dups, common commands, and leading spaces

# Editor
export EDITOR='vim'
export VISUAL='vim'

# Locales
export LANG='en_US.UTF-8'
export LC_COLLATE='C'                   # Traditional ASCII sorting

# BSD and GNU colors
export CLICOLOR='1'
export LSCOLORS='ExFxCxDxbxegedabagacad'
export LS_COLORS='di=01;34:ln=01;35:so=01;32:pi=01;33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:ow=30;42:tw=30;43'

# Command flags
command ls --color ~    &>/dev/null && GNU_COLOR_OPT='--color'
command grep -P . <<< . &>/dev/null && GREP_PCRE_OPT='-P'
command lsof +fg -h     &>/dev/null && LSOF_FLAG_OPT='+fg'
GC_VARS GNU_COLOR_OPT GREP_PCRE_OPT LSOF_FLAG_OPT

# Pager
LESS_ARY=(
    --force                             # Force open non-regular files
    --clear-screen                      # Print buffer from top of screen
    --dumb                              # Do not complain about terminfo errors
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
if __OS_X__; then
    # Prefer not copying Apple doubles and extended attributes
    export COPYFILE_DISABLE=1
    export COPY_EXTENDED_ATTRIBUTES_DISABLE=1
fi

### Meta Utility Functions

# Lists of aliases and functions
showfunctions() { set | grep '^[^ ]* ()'; }
showconflicts() {
    {
        local cmd buf

        builtin alias | command perl -pe 's:alias (.*?)=.*:\1:p' | while builtin read cmd; do
            buf="$(command type -a "$cmd")"
            if (($(grep -c "$cmd is " <<< "$buf") > 1)); then
                builtin printf "$buf\0"
            fi
        done

        showfunctions | awk '{print $1}' | while builtin read cmd; do
            buf="$(command type -a "$cmd" | grep "$cmd is ")"
            if (($(grep -c . <<< "$buf") > 1)); then
                builtin printf "$buf\0"
            fi
        done
    } | ruby -e 'puts $stdin.read.scan(/(.*?)\0/m).flatten.sort.join("\n\n")'
}

# Return absolute path
# Param: $1 Filename
expand_path() { ruby -e 'print File.expand_path(ARGV.first)' -- "$1"; }

# Param: $1       PATH-style envvar name
# Param: [${@:2}] List of directories to prepend
__prepend_path__() {
    local var="$1"

    if (($# == 1)); then
        ruby -e 'puts "%s=%s" % [ARGV[0], ENV[ARGV[0]]]' -- "$var"
        return
    fi

    local dir path="$(eval "echo \$$var")" newpath
    for dir in "${@:2}"; do
        if newpath="$(ruby -e '
            paths = ARGV[0].split ":"
            dir   = File.expand_path ARGV[1]
            abort unless File.directory? dir
            puts paths.reject { |d| d == dir }.unshift(dir).join(":")
        ' -- "$path" "$dir")"; then
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

### Directories

CD_FUNC -n ..           ..
CD_FUNC -n ...          ../..
CD_FUNC -n ....         ../../..
CD_FUNC -n .....        ../../../..
CD_FUNC -n ......       ../../../../..
CD_FUNC -n .......      ../../../../../..
CD_FUNC cdetc           /etc
CD_FUNC cdrcd           /etc/rc.d /usr/local/etc/rc.d
CD_FUNC cdmnt           /mnt
CD_FUNC cdopt           /opt
CD_FUNC cdbrew          /opt/brew
CD_FUNC cddnsmasq       /etc/dnsmasq /opt/dnsmasq/etc && export cddnsmasq
CD_FUNC cdnginx         /etc/nginx /opt/nginx/etc /usr/local/etc/nginx && export cdnginx # Export for vim mapping
CD_FUNC cdtmp           ~/tmp "$TMPDIR" /tmp
CD_FUNC cdvar           /var
CD_FUNC cdlog           /var/log
CD_FUNC cdwww           /srv/http /srv/www /var/www
CD_FUNC cdapi           "$cdwww/api" && export cdapi # Export for `genapi`
CD_FUNC cdconfig        ~/.config
CD_FUNC cdlocal         ~/.local /usr/local
CD_FUNC cdLOCAL         /usr/local
CD_FUNC cdhaus          ~/.haus /opt/haus && export cdhaus RUBYLIB="$cdhaus/lib/ruby"
CD_FUNC cdpass          ~/.password-store
CD_FUNC cdsrc           ~/src ~guns/src /usr/local/src && export cdsrc # Export for edit bindings
CD_FUNC cdSRC           "$cdsrc/READONLY"
CD_FUNC cdvimfiles      "$cdsrc/vimfiles"
CD_FUNC cdmetasploit    "$cdsrc/metasploit" && export cdmetasploit # Export for vim autocmd
CD_FUNC cddownloads     ~/Downloads ~guns/Downloads
CD_FUNC cddocuments     ~/Documents ~guns/Documents
CD_FUNC cdmail          ~/Mail ~guns/Mail

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

### Files, Disks, and Memory

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
if __OS_X__; then
    alias ls@='ls -@'
    alias lse='ls -e'
fi
alias lsb='lsblk -a; echo; blkid'
[[ -d /dev/mapper ]] && alias lsmapper='ls /dev/mapper'
for _d in /dev/disk/by-*; do
    eval "alias ls${_d##*/by-}=\"ls $_d\""
done
unset _d
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

# objdump hexdump strings hexfiend
ALIAS hex='hexdump -C'         && hexl()     { hexdump -C "$@" | pager; }
ALIAS strings='strings -t x -' && lstrings() { strings -t x - "$@" | pager; }
ALIAS ox='objdump -x'
HAVE '/Applications/Hex Fiend.app/Contents/MacOS/Hex Fiend' && {
    alias hexfiend='open -a "/Applications/Hex Fiend.app"'
}

# find
# Param: [$1] Directory to search, if extant
# Param: [$@] Options to find
f() {
    ruby -r shellwords -e '
        cmd, args = ["find"], ARGV.empty? ? ["."] : ARGV.dup
        cmd.push File.directory?(args.first) ? args.shift.chomp("/") : "."
        if args.first =~ /\A-.*|\A\(\z/
            cmd.concat args
        elsif args.any?
            pattern = args.shift
            pattern = case pattern
            when /\A\^.*\$\z/ then pattern.sub(/\^/,"").chomp("$")
            when /\A\^/       then "%s*" % pattern.sub(/\^/,"")
            when /\$\z/       then "*%s" % pattern.chomp("$")
            else                   "*%s*" % pattern
            end
            cmd.push "-iname", pattern, *args
        end
        cmd.push "-print", "-delete" if cmd.delete "-delete"
        warn "\e[32;1m%s\e[0m" % cmd.shelljoin
        exec *cmd
    ' -- "$@"
}; TCOMP find f
f1() { f "$@" -maxdepth 1; };               TCOMP find f1
ff() { f "$@" \( -type f -o -type l \); };  TCOMP find ff
fF() { f "$@" -type f; };                   TCOMP find fF
fd() { f "$@" -type d; };                   TCOMP find fd
fl() { f "$@" -type l; };                   TCOMP find fl
fnewer() { f "$@" -newer /tmp/timestamp; }; TCOMP find fnewer
stamp() { run touch /tmp/timestamp; }
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
alias cpr='cp -r'
alias mv='mv -v'
swap-files() {
    ruby -r fileutils -r digest/sha1 -e "
        include FileUtils::Verbose

        abort 'Usage: $FUNCNAME f₁ f₂' unless ARGV.size == 2
        ARGV.each { |f| raise %Q(No permissions to write #{f.inspect}) unless File.lstat(f).writable? }

        f₁, f₂ = ARGV
        tmp = f₁ + '.' + Digest::SHA1.hexdigest(f₁)
        abort '%s exists!' % tmp if File.exists? tmp
        mv f₁,  tmp
        mv f₂,  f₁
        mv tmp, f₂
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
alias mkdir='mkdir -v'
alias mkdirp='mkdir -p'

# df du
alias df='df -h'
alias du='du -h'
alias dus='du -s'
# Param: [$@] Files to list
dusort() {
    ruby -r shellwords -e '
        fs              = ARGV.empty? ? Dir["*", ".*"].reject { |f| f == "." || f == ".." } : ARGV
        idx, size,      = -1, fs.count
        res, pool, lock = [], [], Mutex.new
        label           = "\r%#{size.to_s.length}d/#{size}"

        # Threading mostly for for user feedback.
        # Will usually be slower than a single call to `du`
        4.times do
            pool << Thread.new do
                loop do
                    i = lock.synchronize { idx += 1 }
                    break if i >= size
                    $stderr.print label % (i+1)
                    # du -k is a POSIX flag
                    res[i] = [%x(du -k -s #{fs[i].shellescape})[/^\d+/].to_i * 1024, fs[i]]
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
    ' -- "$@"
}

# mount
ALIAS mt='mount -v' \
      umt='umount -v' \
      mtext4='mount -v -t ext4' \
      mthfs='mount -v -t hfsplus' \
      mtvfat='mount -v -t vfat' && {
    mtusb() {
        ruby -r shellwords -r set -r fileutils -e '
            options = %w[noatime nodev nodiratime noexec nosuid]
            no_owners = Set.new %w[fat vfat hfs iso9660 ntfs udf]
            uid = ENV["SUDO_UID"] || Process.euid
            gid = ENV["SUDO_GID"] || Process.egid

            blkdevs = Hash[%x(blkid).lines.map do |l|
                f, kvs = l.split(":", 2)
                [f, Hash[kvs.shellsplit.map { |kv| kv.split "=" }]]
            end]

            usbdevs = Hash[Dir["/dev/disk/by-id/usb-*"].map do |l|
                [File.expand_path(File.readlink(l), File.dirname(l)), l]
            end]

            (blkdevs.keys & usbdevs.keys).each do |dev|
                label = blkdevs[dev]["LABEL"]
                type = blkdevs[dev]["TYPE"]
                mtpt = File.join "/mnt", label ? "usb-" + label : File.basename(usbdevs[dev])
                FileUtils.mkdir_p mtpt
                opts = options
                opts += %W[uid=#{uid} gid=#{gid}] unless no_owners.include? type
                cmd = %W[mount -v -o #{opts.join ","} #{dev} #{mtpt}]
                puts cmd.shelljoin
                system *cmd
            end
        ' -- "$@"
    }
    umtusb() { run umount -v /mnt/usb-*; rmdir /mnt/usb-*; }
}

# fusermount
ALIAS fumt='fusermount -u'

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
guntar() { untar -z "$@"; }
buntar() { untar -j "$@"; }

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
ddsize() {
    [[ $# -ge 2 ]] || { echo "Usage: $FUNCNAME size block-size [dd-args]"; return 1; }
    ruby -e '
        size, bs = ARGV.take(2).map do |arg|
            arg.scan(/([\d\.]+)(\D*)/).reduce 0 do |sum, (num, unit)|
                sum + case unit
                when /\Ag\z/i then num.to_f * 2**30
                when /\Am\z/i then num.to_f * 2**20
                when /\Ak\z/i then num.to_f * 2**10
                else               num.to_f
                end
            end.round
        end

        dd = %w[dcfldd dd].map { |c| %x(/bin/sh -c "command -v #{c}").chomp }.find do |path|
            File.executable? path
        end

        raise "#{ARGV[0]} not a multiple of #{ARGV[1]}" if not (size % bs).zero?

        cmd = %W[#{dd} bs=#{bs} count=#{size / bs}] + ARGV.drop(2)
        puts cmd.join(" ")
        exec *cmd
    ' -- "$@"
}; TCOMP dd ddsize

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
if __OS_X__; then
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

# Linux /proc /sys
__LINUX__ && {
    drop_caches() {
        local cmd='echo 1 > /proc/sys/vm/drop_caches'
        echo "$cmd"
        eval "$cmd"
    }
}

# Random file
randfile() {
    ruby -roptparse -e '
        r = ARGV.getopts("r")["r"]
        glob = File.join ARGV.first || ".", r ? "**/*" : "*"
        puts Dir[glob].select { |f| File.file? f }.shuffle.last
    ' -- "$@"
}

### Processes

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

ALIAS s='sudo' \
      root='exec sudo -Hs'
HAVE su && alias xsu='exec su' && TCOMP su xsu

### Network

if HAVE ip; then
    alias a='ip addr'
    alias cidr='ip route list scope link | awk "{print \$1; exit}"'
elif HAVE ifconfig; then
    alias ic='ifconfig'
fi
ALIAS netstatnr='netstat -nr'
ALIAS airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport' \
      ap='airport'
ALIAS net='netcfg' \
      netstop='netcfg -a'
ALIAS net='netctl' \
      netstop='netctl stop-all'

# cURL
ALIAS get='curl -A Mozilla/5.0 -#L' \
      geto='curl -A Mozilla/5.0 -#LO' && {
    alias getip='CURL_CA_BUNDLE=~/.certificates/getip.sungpae.com.crt ruby -e "puts %x(curl -Is https://getip.sungpae.com)[/^X-Client-IP: (.*)/, 1]"'
    httpget() {
        ruby -r webrick -e '
            req = WEBrick::HTTPRequest.new WEBrick::Config::HTTP
            req.parse $stdin
            cmd = %W[curl -#LA #{req.header["user-agent"].first || "Mozilla/5.0"}]
            cmd << "-o" << ARGV.first unless ARGV.empty?
            cmd << req.request_uri.to_s
            warn cmd.inspect
            exec *cmd
        ' -- "$@"
    }
}

# DNS
ALIAS digx='dig -x' \
      digs='dig +short'
if __OS_X__; then
    alias resolv='ruby -e "puts %x(scutil --dns).scan(/resolver #\d\s+nameserver\[0\]\s+:\s+[\h.]+/)"'
else
    alias resolv='cat /etc/resolv.conf'
fi

# NTP
alias qntp='ntpd -g -q'

# netcat
HAVE nc   && complete -F _known_hosts nc
HAVE ncat && complete -F _known_hosts ncat

# tcpdump
HAVE tcpdump && {
    alias pcapdump='tcpdump -n -XX -r'
}

# ssh scp
ALIAS ssh='ssh -2' \
      ssh-password='ssh -o \"PreferredAuthentications password\"' \
      ssh-remove-host='ssh-keygen -R' && complete -F _known_hosts ssh-remove-host && {
    ssh-install-authorized-keys() {
        ruby -r etc -r fileutils -r set -e '
            auth = "authorized_keys"

            ARGV.each do |arg|
                user = Etc.getpwnam arg

                Dir.chdir File.join(user.dir, ".ssh") do
                    authpath = File.join user.dir, ".ssh", auth

                    if File.symlink? auth and File.readlink(auth) == "/dev/null"
                        warn "%s is linked to /dev/null" % authpath
                        next
                    end

                    pubkeys = Dir["*.pub"].reduce(Set.new) { |s, f| s.merge File.read(f).split("\n") }
                    authkeys = Set.new File.exists?(auth) ? File.read(auth).split("\n") : []

                    next if pubkeys.subset? authkeys

                    FileUtils.cp auth, "authorized_keys.old" if File.exists? auth

                    ks = (pubkeys - authkeys).to_a
                    warn "Adding %s key%s to %s" % [ks.count, ks.count == 1 ? "" : "s", authpath]

                    File.open auth, "a" do |f|
                        f.puts ks
                    end
                end
            end
        ' -- "${@:-$USER}"
    }
}
ALIAS scp='scp -2' \
      scpr='scp -r' \
HAVE ssh-shell && alias xssh-shell='exec ssh-shell'
HAVE ssh-proxy && TCOMP ssh ssh-proxy
HAVE sshuttle && {
    TCOMP ssh sshuttle
    TCOMP ssh sshuttle-wrapper
}

# lsof
ALIAS lsof="lsof -Pn $LSOF_FLAG_OPT" && {
    alias lsif='lsof -i'
    alias lsifr="\lsof -Pi $LSOF_FLAG_OPT"
    alias lsifudp='lsif | grep UDP'
    alias lsiflisten='lsif | grep -w "\(LISTEN\)\|UDP"'
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
    _msf() { __compreply__ "$(lsx "$cdmetasploit" | sed 's/^msf//')"; }
    complete -F _msf msf
}

# Weechat
HAVE weechat-curses && {
    ((EUID > 0)) && alias irc='(cd ~/.weechat && envtmux weechat-curses)'
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

### Firewalls

# iptables
[[ -x /etc/iptables/iptables.sh ]] && alias iptables.sh='run /etc/iptables/iptables.sh'

### Editors

# Exuberant ctags
ALIAS ctagsr='ctags -R'

# Vim
HAVE vim && {
    alias vimnilla='command vim -u NONE -N'
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

    # Diff mode for pacnew files
    vimpacnew() {
        ruby -r shellwords -e '
            files = %x(find . -name "*.pacnew" \\( -type f -o -type l \\) -print0).split "\0"
            exec "vim", *files.reduce([]) { |as, f|
                as << "-c" << "edit #{f.shellescape} | diffthis | vsplit #{f.chomp(".pacnew").shellescape} | diffthis | tabnew"
            }, "-c", "tabclose | tabfirst" if files.any?
        '
    }

    vimsession() {
        if [[ -e Session.vim ]]; then
            vim -S Session.vim -c "silent! ! rm -f Session.vim" -c "redraw!" "$@"
        else
            vim "$@"
        fi
    }

    # vim-fugitive
    alias vimgit='vim -c "call fugitive#detect(\".\")" -c Gstatus'
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
    alias viminputrc='(cdhaus && exec vim etc/inputrc)'
    alias vimiptables='(cdetc && exec vim iptables/iptables.sh)'
    alias vimmappings='(cdhaus && exec vim etc/vim/local/mappings.vim)'
    alias vimmuttrc='(cdhaus && exec vim etc/%mutt/muttrc)'
    alias vimnginx='(cdnginx && exec vim nginx.conf)'
    alias vimorg='vim -c Org!'
    alias vimprojectclj='vim "$cdsrc/leiningen/sample.project.clj"'
    alias vimhausrakefile='(cdhaus && exec vim Rakefile)'
    alias vimscratch='vim -c Scratch'
    alias vimsshconfig='(cd ~/.ssh && exec vim config)'
    alias vimtodo='vim -c "Org! TODO"'
    alias vimtmux='(cdhaus && exec vim etc/tmux.conf)'
    alias vimunicode='(cdhaus && exec vim share/doc/unicode-table.txt.gz)'
    alias vimrc='(cdhaus && exec vim etc/vimrc)'
    alias vimperatorrc='(cdhaus && exec vim etc/vimperatorrc)'
    alias vimwm='(cdhaus && exec vim -c "setfiletype clojure" bin/openbox-configuration)'
    alias vimxinitrc='vim ~/.xinitrc'
    alias vimxautostart='(cd ~/.config/openbox && exec vim autostart)'
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
      mkej='make -ej\$\(grep -c ^processor /proc/cpuinfo\)'
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

    # Github
    # Param: $1   User name
    # Param: $2   Repository name
    # Param: [$3] Branch name
    githubclone() {
        (($# == 1 || $# == 2)) || { echo "Usage: $FUNCNAME user/repo [branch]"; return 1; }
        local user="${1%%/*}" repo="${1#*/}" branch
        [[ $2 ]] && branch="--branch $2"
        run git clone $branch "git://github.com/$user/$repo.git"
    }

    # PS1 git status
    REQUIRE ~/.bashrc.d/git-prompt.sh
    gitps1() {
        __ps1toggle__ '/\\w/\\w\$(__git_ps1 " → \[\033[3m\]%s\[\033[23m\]")'
    }; gitps1
}
githubget() {
    (($# == 2 || $# == 3)) || { echo "Usage: $FUNCNAME user/repo [branch]"; return 1; }
    local user="${1%%/*}" repo="${1#*/}" branch="${2:master}"
    run curl -#L "https://github.com/$user/$repo/tarball/$branch"
}
HAVE git-hg && alias git-hg-pull='run git-hg pull --force --rebase'

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

    # Create a private build of a gem
    gem-private-build() {
        ruby -rubygems -r fileutils -e "
            abort 'Usage: $FUNCNAME spec suffix [outdir]' unless (2..3) === ARGV.size

            specfile, suffix, outdir = ARGV
            spec = Gem::Specification.load specfile
            spec.version = '%s.%s' % [spec.version, suffix]
            gem = Gem::Builder.new(spec).build
            FileUtils.mv gem, outdir if outdir
        " -- "$@"
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

# Leiningen, Clojure package manager
HAVE lein && {
    lein() {
        if [[ "$1" == +([0-9]) ]]; then
            local trampoline="trampoline"
            local LEIN_JVM_OPTS+="$LEIN_JVM_OPTS -Xmx$1m -Djavax.net.ssl.trustStore=~/.certificates/leiningen.ks"
            local JVM_OPTS+="$JVM_OPTS -Xmx$1m -Djavax.net.ssl.trustStore=~/.certificates/leiningen.ks"
            shift
        fi
        LEIN_JVM_OPTS="$LEIN_JVM_OPTS" JVM_OPTS="$JVM_OPTS" run lein $trampoline "$@"
    }

    # alias leine=
    # alias leing=
    alias leini='run lein install'
    # alias leinq=
    alias leins='run lein search'
    # alias leinu=
    # alias leinsync=
    alias leinoutdated='run lein ancient :all :check-clojure :allow-qualified :allow-snapshots'
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
    with-pgpass() {
        if [[ ! -e ~/.pgpass ]]; then
            > ~/.pgpass
            command chmod 0600 ~/.pgpass
            echo "*:*:*:*:$(pass "$HOSTNAME/postgresql/guns")" > ~/.pgpass
            ((sleep 1; command rm ~/.pgpass) &) &
        fi
        "$@"
    }; TCOMP exec with-pgpass
    psql() { with-pgpass command psql "${@:-postgres}"; }
    ALIAS aspostgres='sudo -iu postgres'
}

ALIAS sqlite='sqlite3' && {
    # Param: $1 SQLite db
    sqliteschema() {
        {   sqlite3 "$1" <<< .schema
            local t tables=($(sqlite3 "$1" <<< .table))
            for t in "${tables[@]}"; do
                echo -e "\n$t:"
                sqlite3 "$1" <<< "SELECT * FROM $t ORDER BY ROWID DESC LIMIT 1;"
            done
        } 2>/dev/null | pager
    }

    sqlite-firefox-dump-history() {
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

### Hardware control

ALIAS mp='modprobe -a'
ALIAS sens='sensors'

ALIAS rfk='rfkill' && {
    alias rfdisable='run rfkill block all'
    alias rfenable='run rfkill unblock all'
}

if __OS_X__; then
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

# NSS
[[ -e /usr/lib/libnssckbi.so ]] && {
    alias disable-nss-roots='chmod 0 /usr/lib/libnssckbi.so'
    alias enable-nss-roots='chmod 0644 /usr/lib/libnssckbi.so'
}

# GnuPG
# HACK: This allows us to define a default encrypt-to in gpg.conf for
#       applications like mutt
ALIAS gpg='gpg2 --no-encrypt-to' || ALIAS gpg='gpg --no-encrypt-to'

# pass
HAVE pass && {
    # We want pc() to suppress the trailing newline
    pc() { pass "$@" | ruby -e 'print $stdin.gets("\n").chomp' | clip; }; TCOMP pass pc
    passl() { pass "$@" | pager; }; TCOMP pass passl
    passi() { pass insert -fm "$1" < <(genpw "${@:2}") &>/dev/null; pass "$1"; }; TCOMP pass passi
    passiclip() { passi "$@" | clip; }; TCOMP pass passiclip
}

# cryptsetup
ALIAS cs='cryptsetup' && {
    csmount() {
        (($# >= 2)) || { echo "USAGE: $FUNCNAME device mountpoint [keyfile [header]]"; return 1; }
        local device="$1" mountpoint="$2" keyfile="$3" header="$4"
        local name="$(ruby -e 'puts File.basename(File.expand_path ARGV.first)' -- "$mountpoint")"
        local opts=() args=()
        [[ "$header" ]] && opts+=(--header "$header")
        [[ "$keyfile" ]] && opts+=(--key-file "$keyfile")
        if run cryptsetup "${opts[@]}" luksOpen "$device" "$name"; then
            run mount -t auto "/dev/mapper/$name" "$mountpoint"
        fi
    }
    csumount() {
        (($# == 1)) || { echo "USAGE: $FUNCNAME mountpoint"; return 1; }
        if run umount "$1"; then
            run cryptsetup luksClose "$(ruby -e 'puts File.basename(File.expand_path ARGV.first)' -- "$1")"
        fi
    }; TCOMP umount csumount
    alias csdump='cryptsetup luksDump'
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

if __OS_X__; then
    alias list-keychains='find {~,,/System}/Library/Keychains -type f -maxdepth 1'
    alias security-dump-certificates='run security export -t certs'
fi

### Virtual Machines

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

if __OS_X__; then
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

        alias paclog='pager /var/log/pacman.log'
        pacinstallfile() {
            local OPTIND OPTARG opt force
            while getopts :f opt; do
                case $opt in
                f) force='--force';;
                esac
            done
            shift $((OPTIND-1))

            (($# > 0)) || { echo "USAGE: $FUNCNAME [-f] pkg …" >&2; return 1; }

            # Installing from a URL copies the package to /var/cache/pacman
            local pkgs=() pkg
            for pkg in "$@"; do
                pkgs+=("file://$(expand_path "$pkg")")
            done

            pacman -U $force "${pkgs[@]}"
        }
    }

    ALIAS mkpkg='makepkg' \
          mkpkgf='makepkg -f' \
          mkpkgs='makepkg -s'
fi

### Media

# Imagemagick
ALIAS geometry='identify -format \"%w %h\"'

# feh
HAVE feh && {
    ALIAS fshow='feh -r' \
          frand='feh -rz' \
          ftime='feh -Smtime'
    fehbg() {
        ruby -r shellwords -e '
            if ARGV.empty?
                system "feh", File.expand_path(File.read(File.expand_path "~/.fehbg").shellsplit.last)
            else
                system "feh", "--bg-fill", ARGV.first
            end
        ' -- "$@"
    }
    fmove() {
        ruby -r shellwords -r optparse -e '
            dirs, op = [], "mv"
            options = OptionParser.new do |opt|
                opt.banner = "USAGE: fmove [options] [feh-args]\n\nOptions:\n"
                opt.on("-c") { op = "cp" }
                opt.on "-d DIR" do |d|
                    if Dir.exists? d and File.writable? d
                        dirs << d
                    end
                end
            end
            args = options.parse ARGV
            actions = dirs.flat_map.with_index { |d,i| ["--action#{i+1}", "#{op} -- %F #{d.shellescape}"] }
            exec "feh", "-Smtime", "--draw-actions", *actions, *args
        ' -- "$@"
    }
    fcopy() { fmove -c "$@"; }
}

# cmus
HAVE cmus && {
    alias cmus='envtmux cmus'
}

HAVE ffmpeg && {
    alias voicerecording='sleep 0.5; ffmpeg -f alsa -ac 2 -i pulse -acodec pcm_s16le -af bandreject=frequency=60:width_type=q:width=1.0 -y'
    # alias screenrecording='ffmpeg'
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

# Clipboard
clip() {
    if type xsel &>/dev/null; then
        xsel -ib "$@"
    elif type xclip &>/dev/null; then
        xclip -i -selection clipboard "$@"
    elif type pbcopy &>/dev/null; then
        pbcopy "$@"
    fi
}

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

# GTK
HAVE gtk-update-icon-cache && gtk-update-icon-cache-all() {
    local dir
    for dir in ~/.icons/*; do
        [[ -d "$dir" ]] && run gtk-update-icon-cache -f -t "$dir"
    done
}

### TTY

if [[ "$TERM" == linux ]]; then
    alias vconsole-setup="loadkeys '$cdhaus/share/kbd/macbook.map.gz'; unicode_start"
fi

ALIAS rl='rlwrap'

### Init

if HAVE systemctl; then
    ALIAS sd='/usr/lib/systemd/systemd' \
          sc='systemctl' \
          jc='journalctl --full' \
          jcb='journalctl --full -b' \
          jcf='journalctl --full -f' && {
        alias scdaemonreload='systemctl --system daemon-reload'
        alias sleepnow='systemctl suspend'
        alias daemons='ruby -e "puts %x(systemctl list-units).lines.select { |l| l.split[3] == %q(running) }"'
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

if __OS_X__; then
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

ALIAS kf='kupfer'

: # Return true
