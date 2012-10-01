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
#            '8>                                          guns <self@sungpae.com>
#             "
#
#  cf. http://inai.de/documents/Perfect_Ruleset.pdf
#
#  Note that this file should not be used directly as an init script. Set the
#  firewall state once with this script, then dump with iptables-save.

set -e

printf 'Loading iptables rules... '

#
# Initialization
#

test -n "$IPTABLES" || IPTABLES=$(command -v iptables)
test -x "$IPTABLES" || { echo "Could not execute $IPTABLES"; exit 1; }

# Flush rules and delete non-default chains
for TABLE in filter nat mangle raw security; do
    $IPTABLES --table $TABLE --flush
    $IPTABLES --table $TABLE --delete-chain
done

# Default policies
$IPTABLES --policy INPUT   DROP
$IPTABLES --policy FORWARD DROP
$IPTABLES --policy OUTPUT  ACCEPT

# Disable IPv6 until hell freezes over
test -n "$IP6TABLES" || IP6TABLES=$(command -v ip6tables)
test -x "$IP6TABLES" && test -e /proc/net/if_inet6 && {
    printf 'Filtering IPv6... '
    for TABLE in filter mangle raw security; do
        $IP6TABLES --table $TABLE --flush
        $IP6TABLES --table $TABLE --delete-chain
    done
    $IP6TABLES --policy INPUT   DROP
    $IP6TABLES --policy FORWARD DROP
    $IP6TABLES --policy OUTPUT  DROP
}

# Packet tracing / logging
# $IPTABLES --table raw --append PREROUTING/OUTPUT [--match ...] --jump TRACE
# $IPTABLES --new-chain LOGDROP
# $IPTABLES --append    LOGDROP   --jump LOG
# $IPTABLES --append    LOGDROP   --jump DROP
# $IPTABLES --new-chain LOGACCEPT
# $IPTABLES --append    LOGACCEPT --jump LOG
# $IPTABLES --append    LOGACCEPT --jump ACCEPT

#
# Core rules
#

# Stateful rule
$IPTABLES --append INPUT --match conntrack --ctstate ESTABLISHED --jump ACCEPT

# Loopback access
$IPTABLES --append INPUT  --in-interface  lo --jump ACCEPT
# $IPTABLES --append OUTPUT --out-interface lo --jump ACCEPT # Uncomment if OUTPUT policy is DROP

# ICMP
$IPTABLES --append INPUT --protocol icmp --match conntrack --ctstate NEW,RELATED --jump ACCEPT

#
# Security
#

$IPTABLES --append INPUT --match conntrack --ctstate INVALID --jump DROP

#
# Services
#

# Host based exception
# $IPTABLES --append INPUT --source VMHOST --match conntrack --ctstate NEW --jump ACCEPT

# SSH
# $IPTABLES --append INPUT --protocol tcp --dport 22 --match conntrack --ctstate NEW --jump ACCEPT

# HTTP
# $IPTABLES --append INPUT --protocol tcp --dport 80  --match conntrack --ctstate NEW --jump ACCEPT
# $IPTABLES --append INPUT --protocol tcp --dport 443 --match conntrack --ctstate NEW --jump ACCEPT
# $IPTABLES --append INPUT --protocol tcp --match multiport --dports 80,443 --match conntrack --ctstate NEW --jump ACCEPT

# NFS
# $IPTABLES --append INPUT --protocol tcp --dport 111   --match conntrack --ctstate NEW --jump ACCEPT
# $IPTABLES --append INPUT --protocol udp --dport 111   --match conntrack --ctstate NEW --jump ACCEPT
# $IPTABLES --append INPUT --protocol tcp --dport 2049  --match conntrack --ctstate NEW --jump ACCEPT
# $IPTABLES --append INPUT --protocol tcp --dport 32767 --match conntrack --ctstate NEW --jump ACCEPT

# NTP
# $IPTABLES --append INPUT --protocol udp --dport 123 --jump ACCEPT

# Samba
# $IPTABLES --append INPUT --protocol tcp --match multiport --dports 139,445 --match conntrack --ctstate NEW --jump ACCEPT
# $IPTABLES --append INPUT --protocol udp --match multiport --dports 137,138 --match conntrack --ctstate NEW --jump ACCEPT

echo 'OK'
