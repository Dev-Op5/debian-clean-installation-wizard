#!/bin/sh
### BEGIN INIT INFO
# Provides:          datacenter-gateway
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: local network/firewall scripts
# Description:       apply the init of local network/firewall scripts at boot time.
# Author:            eRQee (q@serverq.org)
### END INIT INFO

PATH=/usr/sbin:/sbin:/bin:/usr/bin

# declaring interfaces
outif="vmbr0" # the ethernet card connected to the internet
lanif="vmbr1" # the one connected to the lan

# delete all existing rules.
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Always accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections, and those not coming from the outside
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state NEW ! -i $outif -j ACCEPT
iptables -A FORWARD -i $outif -o $lanif -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop all null packets
# iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Allow outgoing connections from the LAN side
iptables -A FORWARD -i $lanif -o $outif -j ACCEPT

# Masquerading
iptables -t nat -A POSTROUTING -o $lanif -j MASQUERADE
iptables -t nat -A POSTROUTING -o $outif -j MASQUERADE

# Don't forward from the outside to the inside
iptables -A FORWARD -i $outif -o $outif -j REJECT

# allow the DHCP server
iptables -A INPUT -s 172.57.58.0/24 -i $outif -p tcp --sport 68 --dport 67 -j ACCEPT
iptables -A INPUT -s 175.57.58.0/24 -i $outif -p udp --sport 68 --dport 67 -j ACCEPT

######################################
# Port Forwarding to local resources #
######################################

#iptables -t nat -A PREROUTING -p tcp --dport 22105 -j DNAT --to-destination 172.57.58.105:22            #SSH tunnel to VM105
#iptables -t nat -A PREROUTING -p tcp --dport 22106 -j DNAT --to-destination 172.57.58.106:22            #SSH tunnel to VM106
#iptables -t nat -A PREROUTING -p tcp --dport 22108 -j DNAT --to-destination 172.57.58.108:22            #SSH tunnel to VM108
#iptables -t nat -A PREROUTING -p tcp --dport 22109 -j DNAT --to-destination 172.57.58.109:22            #SSH tunnel to VM109
#iptables -t nat -A PREROUTING -p tcp --dport 22111 -j DNAT --to-destination 172.57.58.111:22            #SSH tunnel to VM111
#iptables -t nat -A PREROUTING -p tcp --dport 25432 -j DNAT --to-destination 172.57.58.106:5432          #SSH Anggota.B.ID PostgreSQL Direct

######################################
# Enable the Routes                  #
######################################

echo 1 > /proc/sys/net/ipv4/ip_forward
echo "datacenter-gateway has been successfully launched"

exit 0