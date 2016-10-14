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
# Functions
#

test -n "$IPTABLES" || IPTABLES="$(command -v iptables)"
test -x "$IPTABLES" || { echo "Could not execute $IPTABLES" >&2; exit 1; }

iptables() { "$IPTABLES" "$@"; }

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
    iptables --append    "$name" --jump LOG --log-prefix "[$name] "
    if [[ "$tcp" == "tcp-reset" ]]; then
        iptables --append "$name"  --protocol tcp --jump REJECT --reject-with tcp-reset
    fi
    iptables --append    "$name" --jump "$target"
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

accept_input()  { iptables --append INPUT   "$@" --match conntrack --ctstate NEW --jump ACCEPTINPUT; }
accept_inputq() { iptables --append INPUT   "$@" --match conntrack --ctstate NEW --jump ACCEPT;      }
allow_output()  { iptables --append OUTPUT  "$@" --match conntrack --ctstate NEW --jump ACCEPT;      }
drop_input()    { iptables --append INPUT   "$@" --jump DROPINPUT;   }
drop_output()   { iptables --append OUTPUT  "$@" --jump DROPOUTPUT;  }
drop_forward()  { iptables --append FORWARD "$@" --jump DROPFORWARD; }

#
# Initialization
#

reset_rules "$IPTABLES" DROP

# IPv6
test -n "$IP6TABLES" || IP6TABLES="$(command -v ip6tables)"
test -x "$IP6TABLES" && test -e /proc/net/if_inet6 && {
    printf 'Initializing IPv6... '
    reset_rules "$IP6TABLES" DROP
}

#
# Chains
#

new_chain INVALID     DROP
new_chain DROPINPUT   DROP tcp-reset
new_chain DROPOUTPUT  DROP tcp-reset
new_chain DROPFORWARD DROP tcp-reset
new_chain ACCEPTINPUT ACCEPT

#
# INPUT
#

minimal_passthrough INPUT

# SSH
# accept_input --protocol tcp --dport 22

# HTTP
# accept_input --protocol tcp --dport 80
# accept_input --protocol tcp --dport 443
# accept_input --protocol tcp --match multiport --dports 80,443

# DNS
# accept_input --protocol udp --in-interface eth0 --dport 53

# NFS
# accept_input --protocol udp --dport 111
# accept_input --protocol tcp --match multiport --dports 111,2049,32767

# Samba
# accept_input --protocol udp --dport 137:138
# accept_input --protocol tcp --match multiport --dports 139,445

# DHCP
# accept_input --protocol udp --in-interface vboxnet0 --sport 67:68 --dport 67:68

# LAN
# accept_input --source 192.168.1.0/24

drop_input

#
# FORWARD
#

# Blacklisted domains
# drop_forward --match set --match-set BLACKLIST dst

# Forward host
# iptables --append FORWARD --destination "$HOST" --match conntrack --ctstate ESTABLISHED --jump ACCEPT
# iptables --append FORWARD --destination "$HOST" --match conntrack --ctstate INVALID     --jump INVALID
# iptables --append FORWARD --source      "$HOST"                                         --jump ACCEPT
# iptables --append FORWARD --destination "$HOST" --protocol icmp                         --jump ACCEPT

drop_forward

#
# OUTPUT
#

minimal_passthrough OUTPUT

# Blacklisted domains
# drop_output --match set --match-set EXFILTRATION dst

# HTTP
# allow_output --protocol tcp --match multiport --dports 80,443

# Whitelisted domains
# allow_output --match set --match-set DNS dst --protocol udp --match multiport --dports 53,443
# allow_output --match set --match-set SSH dst --protocol tcp --dport 22
# allow_output --match set --match-set NTP dst --protocol udp --dport 123

# LAN
# allow_output --destination 192.168.1.0/24

drop_output

#
# NAT
#

# iptables --table nat --append POSTROUTING --source "$HOST" --jump MASQUERADE

echo 'OK'
