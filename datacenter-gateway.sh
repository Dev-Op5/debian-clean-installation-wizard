#!/bin/sh
### BEGIN INIT INFO
# Provides:          datacenter-gateway
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: NAT Network & firewall scripts
# Description:       apply the initialization of local NAT Network definition & firewall scripts at boot time.
# Author:            eRQee (rizky@prihanto.web.id)
### END INIT INFO

PATH=/usr/sbin:/sbin:/bin:/usr/bin

###
### EDIT THIS SEGMENT with the OS identity of network interfaces, e.g. eth0, ens18, wlan0, wlp4s0, vmbr0, etc. (see ifconfig)
###
#
outif="vmbr0" # the network card connected to the internet
lanif="vmbr1" # the one that connected to the lan/vlan and/or need to be defined as the nodes behind NAT

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
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Allow outgoing connections from the LAN side
iptables -A FORWARD -i $lanif -o $outif -j ACCEPT

# Masquerading
iptables -t nat -A POSTROUTING -o $lanif -j MASQUERADE
iptables -t nat -A POSTROUTING -o $outif -j MASQUERADE

# Don't forward from the outside to the inside
iptables -A FORWARD -i $outif -o $outif -j REJECT

# allow the DHCP server, or disable this 2 line below if you rather not to implement this gateway as DHCP provider.
#### pre-requisites: dnsmasq -- install with : apt install -y dnsmasq 
#### please change the 192.168.0.0 with the subnet address that you use
# 
iptables -A INPUT -s 192.168.0.0/24 -i $outif -p tcp --sport 68 --dport 67 -j ACCEPT
iptables -A INPUT -s 192.168.0.0/24 -i $outif -p udp --sport 68 --dport 67 -j ACCEPT

##########################################
# DMZ/Port Forwarding to local resources #
##########################################

# example:
#iptables -t nat -A PREROUTING -p tcp --dport 22100 -j DNAT --to-destination 192.168.0.100:22 #SSH tunnel example to VM100 via port 22100

######################################
# Enable the Routes                  #
######################################

echo 1 > /proc/sys/net/ipv4/ip_forward
echo "datacenter-gateway has been successfully launched"

exit 0