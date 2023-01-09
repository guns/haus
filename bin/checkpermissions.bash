#!/usr/bin/env bash

# Check shell init files and system paths for loose permissions
checkpermissions.bash() {
    # path:user:group:octal-mask:opt1,opt2
    local specs=(
        /boot

        /etc
        /etc/crypttab:::0077
        /etc/netctl:::0077
        /etc/pacman.d/gnupg/*.d/:::0077:glob
        /etc/pacman.d/gnupg/secring*:::0077:glob
        /etc/ssh/*key:::0077:glob
        /etc/ssl/private:::0077
        /etc/sudoers*::root:0027:glob
        /etc/wireguard:::0077
        /etc/**/.git:::0077:glob,no-recurse

        /home/*:-::0077:glob,no-recurse

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
        ~/.cache/*_history:::0077:glob
        ~/.bash_completion
        ~/.bash_completion.d
        ~/.bash_local
        ~/.inputrc
        ~/.mitmproxy:::0077:no-recurse
        ~/.password-store:::0077:no-recurse
        ~/.rnd:::0177
        ~/.ssh:::0077:no-recurse
        ~/.ssh/*_{dsa,ecdsa,ed25519,rsa}:::0077:glob
        ~/.[^.]*/**/.git:::0077:glob,no-recurse

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

checkpermissions.bash "$@"
