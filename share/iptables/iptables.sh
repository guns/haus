#!/bin/sh
#
#     .                     s                    ..         ..             .x+=:.
#    @88>                  :8              . uW8"     x .d88"             z`    ^%
#    %8P   .d``           .88              `t888       5888R                 .   <k
#     .    @8Ne.   .u    :888ooo      u     8888   .   '888R       .u      .@8Ned8"
#   .@88u  %8888:u@88N -*8888888   us888u.  9888.z88N   888R    ud8888.  .@^%8888"
#  ''888E`  `888I  888.  8888   .@88 "8888" 9888  888E  888R  :888'8888.x88:  `)8b.
#    888E    888I  888I  8888   9888  9888  9888  888E  888R  d888 '88%"8888N=*8888
#    888E    888I  888I  8888   9888  9888  9888  888E  888R  8888.+"    %8"    R88
#    888E  uW888L  888' .8888Lu=9888  9888  9888  888E  888R  8888L       @8Wou 9%
#    888& '*88888Nu88P  ^%888*  9888  9888 .8888  888" .888B .'8888c. .+.888888P`
#    R888"~ '88888F`      'Y"   "888*""888" `%888*%"   ^*888%  "88888%  `   ^"F
#     ""     888 ^               ^Y"   ^Y'     "`        "%      "YP'
#            *8E
#            '8>                                        guns <self@sungpae.com>
#             "
#
#  cf. http://inai.de/documents/Perfect_Ruleset.pdf
#      http://inai.de/images/nf-packet-flow.png
#
#  Note that this file should not be used directly as an init script. Set the
#  firewall state once with this script, then dump with iptables-save.

set -e

echo 'Loading iptables rules...'

#
# Functions
#

test -n "$IPTABLES" || IPTABLES="$(command -v iptables)"
test -x "$IPTABLES" || { echo "Could not execute $IPTABLES" >&2; exit 1; }

iptables() {
    printf "%s %s\n" "$IPTABLES" "$*"
    "$IPTABLES" "$@"
}

reset_rules() {
    test $# -eq 2 || return 1
    local cmd="$1" policy="$2" table=

    # Flush rules and delete non-default chains
    for table in filter nat mangle raw security; do
        "$cmd" --table "$table" --flush
        "$cmd" --table "$table" --delete-chain
    done

    # Set default filter policies
    "$cmd" --policy INPUT   "$policy"
    "$cmd" --policy FORWARD "$policy"
    "$cmd" --policy OUTPUT  "$policy"
}

new_chain() {
    test $# -eq 2 || test $# -eq 3 || return 1
    local name="$1" target="$2" tcp="$3"

    iptables --new-chain "$name"
    iptables --append "$name" --jump LOG --log-prefix "[$name] "
    if [[ "$tcp" == "tcp-reset" ]]; then
        iptables --append "$name" --protocol tcp --jump REJECT --reject-with tcp-reset
    fi
    iptables --append "$name" --jump "$target"
}

minimal_passthrough() {
    test $# -eq 1 || return 1
    local chain="$1" dir=

    case "$chain" in
    INPUT)  local dir='in';;
    OUTPUT) local dir='out';;
    esac

    iptables --append "$chain" --match conntrack --ctstate ESTABLISHED --jump ACCEPT  # Allow established traffic
    iptables --append "$chain" --match conntrack --ctstate INVALID     --jump INVALID # Log and drop invalid packets
    iptables --append "$chain" --${dir}-interface lo                   --jump ACCEPT  # Allow traffic over loopback
    iptables --append "$chain" --protocol icmp                         --jump ACCEPT  # Allow ICMP
}

minimal_host_forwarding() {
    iptables --append FORWARD --destination "$1" --match conntrack --ctstate ESTABLISHED --jump ACCEPT  # Allow established traffic
    iptables --append FORWARD --destination "$1" --match conntrack --ctstate INVALID     --jump INVALID # Log and drop invalid packets
    iptables --append FORWARD --source      "$1" --protocol icmp                         --jump ACCEPT  # Allow outbound ICMP
    iptables --append FORWARD --destination "$1" --protocol icmp                         --jump ACCEPT  # Allow inbound ICMP

    if [[ "$2" ]]; then
        iptables --table nat --append POSTROUTING --source "$1" --jump SNAT --to-source "$2"
    else
        iptables --table nat --append POSTROUTING --source "$1" --jump MASQUERADE
    fi
}

filter() {
    local chain="$1" target state
    local args=("${@:3}")

    IFS=: read target state <<< "$2"
    if [[ "$state" ]]; then
        args+=(--match conntrack --ctstate "$state")
    fi

    iptables --append "$chain" "${args[@]}" --jump "$target"
}

input()   { filter INPUT   "$@"; }
output()  { filter OUTPUT  "$@"; }
forward() { filter FORWARD "$@"; }

#
# Initialization
#

reset_rules "$IPTABLES" DROP

# IPv6
test -n "$IP6TABLES" || IP6TABLES="$(command -v ip6tables)"
test -x "$IP6TABLES" && test -e /proc/net/if_inet6 && {
    echo 'Initializing IPv6...'
    reset_rules "$IP6TABLES" DROP
}

#
# Chains
#

new_chain INVALID           DROP
new_chain DROP_INPUT        DROP tcp-reset
new_chain DROP_OUTPUT       DROP tcp-reset
new_chain DROP_FORWARD      DROP tcp-reset
new_chain ACCEPT_INPUT      ACCEPT

#
# INPUT
#

minimal_passthrough INPUT

# VM
# input ACCEPT:NEW --in-interface vboxnet0

# SSH
# input ACCEPT_INPUT:NEW --protocol tcp --dport 22

# HTTP
# input ACCEPT_INPUT:NEW --protocol tcp --match multiport --dports 80,443

# DNS
# input ACCEPT_INPUT:NEW --protocol udp --in-interface eth0 --dport 53

# DHCP
# input ACCEPT_INPUT:NEW --protocol udp --in-interface vboxnet0 --sport 67:68 --dport 67:68

# NFS
# input ACCEPT_INPUT:NEW --protocol udp --dport 111
# input ACCEPT_INPUT:NEW --protocol tcp --match multiport --dports 111,2049,32767

# Samba
# input ACCEPT:NEW --protocol udp --dport 137:138
# input ACCEPT:NEW --protocol tcp --match multiport --dports 139,445

input DROP_INPUT

#
# FORWARD
#

# HOST
# minimal_host_forwarding "$HOST" "$LAN_IP"
# forward ACCEPT --source "$HOST" --protocol tcp --match multiport --dports 80,443
# forward ACCEPT --source "$HOST" --protocol udp --match multiport --dports 80,443

forward DROP_FORWARD

#
# OUTPUT
#

minimal_passthrough OUTPUT

# Whitelisted domains
output ACCEPT:NEW --match set --match-set DNS dst --protocol udp --match multiport --dports 53,443
output ACCEPT:NEW --match set --match-set SSH dst --protocol tcp --dport 22
output ACCEPT:NEW --match set --match-set NTP dst --protocol udp --dport 123

# VM
output ACCEPT --out-interface vboxnet0

# LAN
output ACCEPT --destination "$LAN"

output DROP_OUTPUT

echo 'OK'
