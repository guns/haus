#!/bin/sh
# http://www.debiantutorials.net/loading-iptables-rules-on-startup/
# http://www.brandonhutchinson.com/iptables_fw.html

echo -n 'Loading iptables rules... '

### Initialization

set -e

test -n "$IPTABLES" || IPTABLES=$(command -v iptables)
test -x "$IPTABLES" || { echo "Could not execute $IPTABLES"; exit 1; }

# Disable IPv6
test -n "$IP6TABLES" || IP6TABLES=$(command -v ip6tables)
test -x "$IP6TABLES" && test -e /proc/net/if_inet6 && {
    echo -n 'Filtering IPv6... '
    $IP6TABLES -t filter --flush
    $IP6TABLES -t mangle --flush
    $IP6TABLES -t raw    --flush
    $IP6TABLES -t filter --delete-chain
    $IP6TABLES -t mangle --delete-chain
    $IP6TABLES -t raw    --delete-chain
    $IP6TABLES -P INPUT   DROP
    $IP6TABLES -P FORWARD DROP
    $IP6TABLES -P OUTPUT  DROP
}

# Flush rules and delete non-default chains
$IPTABLES -t filter --flush
$IPTABLES -t nat    --flush
$IPTABLES -t mangle --flush
$IPTABLES -t raw    --flush
$IPTABLES -t filter --delete-chain
$IPTABLES -t nat    --delete-chain
$IPTABLES -t mangle --delete-chain
$IPTABLES -t raw    --delete-chain

# Default policies
$IPTABLES -P INPUT   DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT  ACCEPT

# # Convenient packet logging
# $IPTABLES -N LOGDROP
# $IPTABLES -A LOGDROP -j LOG
# $IPTABLES -A LOGDROP -j DROP
# $IPTABLES -N LOGACCEPT
# $IPTABLES -A LOGACCEPT -j LOG
# $IPTABLES -A LOGACCEPT -j ACCEPT


### Core rules

# Loopback access
$IPTABLES -A INPUT  -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Stateful rule
$IPTABLES -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ICMP
$IPTABLES -A INPUT -p icmp --icmp-type echo-reply              -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type echo-request            -m state --state NEW                 -j ACCEPT -m limit --limit 5/s
$IPTABLES -A INPUT -p icmp --icmp-type destination-unreachable -m state --state NEW                 -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type time-exceeded           -m state --state NEW                 -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type timestamp-request       -m state --state NEW                 -j ACCEPT
$IPTABLES -A INPUT -p icmp --icmp-type timestamp-reply         -m state --state ESTABLISHED,RELATED -j ACCEPT


### Services


### Security


### Examples

# # Host based exception
# $IPTABLES -A INPUT --source VMHOST -j ACCEPT

# # SSH
# $IPTABLES -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# # HTTP
# $IPTABLES -A INPUT -p tcp --dport 80  -m state --state NEW -j ACCEPT
# $IPTABLES -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

# # NFS
# $IPTABLES -A INPUT -p tcp --dport 111   -m state --state NEW -j ACCEPT
# $IPTABLES -A INPUT -p udp --dport 111   -m state --state NEW -j ACCEPT
# $IPTABLES -A INPUT -p tcp --dport 2049  -m state --state NEW -j ACCEPT
# $IPTABLES -A INPUT -p tcp --dport 32767 -m state --state NEW -j ACCEPT

# # NTP
# $IPTABLES -A INPUT -p udp --dport 123 -j ACCEPT

# # Samba
# $IPTABLES -A INPUT -p tcp -m multiport --dports 139,445 -m state  --state NEW -j ACCEPT
# $IPTABLES -A INPUT -p udp -m multiport --dports 137,138 -j ACCEPT

# # Block new connections without SYN
# $IPTABLES -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

# # Block fragments and Xmas tree as well as SYN,FIN and SYN,RST
# $IPTABLES -A INPUT -p ip -f -j DROP
# $IPTABLES -A INPUT -p tcp --tcp-flags ALL     ACK,RST,SYN,FIN -j DROP
# $IPTABLES -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j DROP
# $IPTABLES -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j DROP

# # Anti-spoofing rules
# $IPTABLES -A INPUT -s 200.200.200.200 -j DROP
# $IPTABLES -A INPUT -s 192.168.0.0/24  -j DROP
# $IPTABLES -A INPUT -s 127.0.0.0/8     -j DROP

echo 'OK'
