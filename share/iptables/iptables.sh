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

printf 'Loading iptables rules... '

#
# Initialization
#

test -n "$IPTABLES" || IPTABLES="$(command -v iptables)"
test -x "$IPTABLES" || { echo "Could not execute $IPTABLES" >&2; exit 1; }

iptables() { "$IPTABLES" "$@"; }

# Flush rules and delete non-default chains
for TABLE in raw mangle nat filter security; do
    iptables --table "$TABLE" --flush
    iptables --table "$TABLE" --delete-chain
done

# Set default policies
iptables --policy INPUT   DROP
iptables --policy FORWARD DROP
iptables --policy OUTPUT  ACCEPT

# Block IPv6 until hell freezes over
test -n "$IP6TABLES" || IP6TABLES="$(command -v ip6tables)"
test -x "$IP6TABLES" && test -e /proc/net/if_inet6 && {
    printf 'Filtering IPv6... '
    for TABLE in raw mangle filter security; do
        "$IP6TABLES" --table "$TABLE" --flush
        "$IP6TABLES" --table "$TABLE" --delete-chain
    done
    "$IP6TABLES" --policy INPUT   DROP
    "$IP6TABLES" --policy FORWARD DROP
    "$IP6TABLES" --policy OUTPUT  DROP
}

unset TABLE

#
# Chains
#

iptables --new-chain DROPINV
iptables --append    DROPINV --jump LOG  --log-prefix '[DROPINV] '
iptables --append    DROPINV --jump DROP

#
# Inbound rules
#

# Allow loopback traffic
iptables --append INPUT  --in-interface  lo --jump ACCEPT
# iptables --append OUTPUT --out-interface lo --jump ACCEPT

# Allow established traffic
iptables --append INPUT --match conntrack --ctstate ESTABLISHED --jump ACCEPT

# Allow ICMP
iptables --append INPUT --protocol icmp --match conntrack --ctstate NEW,RELATED --jump ACCEPT

# Drop invalid input
iptables --append INPUT --match conntrack --ctstate INVALID --jump DROPINV

### Services

accept_new() { "$IPTABLES" --append INPUT "$@" --match conntrack --ctstate NEW --jump ACCEPT; }

# SSH
# accept_new --protocol tcp --dport 22

# HTTP
# accept_new --protocol tcp --dport 80
# accept_new --protocol tcp --dport 443
# accept_new --protocol tcp --match multiport --dports 80,443

# DHCP
# accept_new --protocol udp --in-interface eth0 --sport 67:68 --dport 67:68

# DNS
# accept_new --protocol udp --in-interface eth0 --dport 53

# NFS
# accept_new --protocol udp --dport 111
# accept_new --protocol tcp --match multiport --dports 111,2049,32767

# Samba
# accept_new --protocol udp --dport 137:138
# accept_new --protocol tcp --match multiport --dports 139,445

#
# NAT
#

forward_interface() {
    test $# -eq 2 || return 1;
    local in="$1" out="$2"
    # Outbound
    iptables --append FORWARD --in-interface "$in" --out-interface "$out" --jump ACCEPT
    # Inbound
    iptables --append FORWARD --in-interface "$out" --out-interface "$in"                 --match conntrack --ctstate ESTABLISHED --jump ACCEPT
    iptables --append FORWARD --in-interface "$out" --out-interface "$in" --protocol icmp --match conntrack --ctstate NEW,RELATED --jump ACCEPT
    iptables --append FORWARD --in-interface "$out" --out-interface "$in"                 --match conntrack --ctstate INVALID     --jump DROPINV
    # Enable NAT
    iptables --table nat --append POSTROUTING --out-interface "$out" --jump MASQUERADE
}

# forward_interface eth0 wlan0

echo 'OK'
