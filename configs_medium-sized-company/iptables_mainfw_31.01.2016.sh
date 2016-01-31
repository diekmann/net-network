#!/bin/bash

IPT="/sbin/iptables"
echo 1 > /proc/sys/net/ipv4/ip_forward

$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X
$IPT -t raw -F
$IPT -t raw -X
$IPT -t security -F
$IPT -t security -X
$IPT -P INPUT ACCEPT
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT

$IPT -N TCP
$IPT -N UDP
$IPT -N FW
$IPT -N FW-OPEN


# Allow any outbound traffic
$IPT -P OUTPUT ACCEPT

# Deny all
$IPT -P INPUT DROP
$IPT -P FORWARD DROP



# INPUT ----------------------------------------------------------------------
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -i eth0 -j ACCEPT

# normally we reject packets but those are dropped
$IPT -A INPUT -m conntrack --ctstate INVALID -j LOG --log-prefix "[invalid] "
$IPT -A INPUT -m conntrack --ctstate INVALID -j DROP

$IPT -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT

# For new packets ask the TCP/UDP tables. Reject everything else. Note that
# will reject NEW tcp packets without SYN set.
$IPT -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP
$IPT -A INPUT -p udp -m conntrack --ctstate NEW -j UDP

# Reject everything else
$IPT -A INPUT -p tcp -m recent --set --name TCP-PORTSCAN -j LOG --log-prefix "[portscan] "
$IPT -A INPUT -p udp -m recent --set --name UDP-PORTSCAN -j LOG --log-prefix "[portscan] "
$IPT -A INPUT -p tcp -m recent --set --name TCP-PORTSCAN -j REJECT --reject-with tcp-reset
$IPT -A INPUT -p udp -m recent --set --name UDP-PORTSCAN -j REJECT --reject-with icmp-port-unreachable
$IPT -A INPUT -j LOG --log-prefix "[final reject] "
$IPT -A INPUT -j REJECT --reject-with icmp-proto-unreachable

# TCP chain ------------------------------------------------------------------
# mark suspicious streams as portscan and reject
$IPT -I TCP -p tcp -m recent --update --seconds 60 --name TCP-PORTSCAN -j REJECT --reject-with tcp-reset
# allowed ports
$IPT -A TCP -p tcp --dport 53 -j ACCEPT
$IPT -A TCP -p tcp --dport 7122 -j ACCEPT
# ----------------------------------------------------------------------------

# UDP chain ------------------------------------------------------------------
# mark suspicious streams as portscan and reject
$IPT -I UDP -p udp -m recent --update --seconds 60 --name UDP-PORTSCAN -j REJECT --reject-with icmp-port-unreachable
# allowed ports
$IPT -A UDP -p udp --dport 53 -j ACCEPT
$IPT -A UDP -p udp --dport 1194 -j ACCEPT
# ----------------------------------------------------------------------------

# Anti spoofing --------------------------------------------------------------
$IPT -t raw -I PREROUTING -m rpfilter --invert -j DROP
# ----------------------------------------------------------------------------


# FORWARD chain --------------------------------------------------------------
# traffic accounting
for i in {1..254}
do
	$IPT -A FORWARD -s 172.16.2.$i
	$IPT -A FORWARD -d 172.16.2.$i
done
$IPT -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
$IPT -A FORWARD -j FW
$IPT -A FORWARD -j FW-OPEN
$IPT -A FORWARD -j REJECT --reject-with icmp-host-unreachable
$IPT -t nat -A POSTROUTING -s 172.16.2.0/24 -o ppp0 -j MASQUERADE
# dnat
$IPT -t nat -A PREROUTING -i ppp0 -p tcp --dport 4081 -j DNAT --to 172.16.2.34
$IPT -A FW-OPEN -d 172.16.2.34 -p tcp --dport 4081 -j ACCEPT
# ----------------------------------------------------------------------------


# FW-OPEN chain --------------------------------------------------------------
# general access for all clients
$IPT -A FW-OPEN -i eth0 -p tcp --dport 80 -j ACCEPT
$IPT -A FW-OPEN -i eth0 -p tcp --dport 443 -j ACCEPT
$IPT -A FW-OPEN -i eth0 -p icmp --icmp-type 8 -j ACCEPT
# disable firewall for servers, routers, and some special addresses
$IPT -A FW-OPEN -i eth0 -s 172.16.2.0/28 -j ACCEPT
$IPT -A FW-OPEN -i eth0 -s 172.16.2.248/29 -j ACCEPT
$IPT -A FW-OPEN -i eth0 -s 172.16.2.34/32 -j ACCEPT
$IPT -A FW-OPEN -i eth0 -s 172.16.2.247/32 -j ACCEPT
$IPT -A FW-OPEN -i eth0 -s 172.16.2.230/32 -j ACCEPT
# openvpn
$IPT -A FW-OPEN -s 192.168.255.0/24 -d 172.16.2.0/24 -j ACCEPT
$IPT -A FW-OPEN -d 192.168.255.0/24 -s 172.16.2.0/24 -j ACCEPT
# ----------------------------------------------------------------------------


# FW chain insert REJECT only ------------------------------------------------
# web radio blocklist
$IPT -A FW -d 194.97.153.231  -j REJECT
$IPT -A FW -d 194.97.151.143  -j REJECT
$IPT -A FW -d 151.80.102.139  -j REJECT
$IPT -A FW -d 80.237.184.24   -j REJECT
$IPT -A FW -d 212.45.104.69   -j REJECT
# malicious host blocklist
$IPT -A FW -d 63.245.217.112  -j REJECT
$IPT -A FW -d 213.9.42.248    -j REJECT
$IPT -A FW -d 83.169.59.64    -j REJECT
$IPT -A FW -d 94.198.59.132   -j REJECT
$IPT -A FW -d 94.198.59.134   -j REJECT
$IPT -A FW -d 178.250.2.98    -j REJECT
$IPT -A FW -d 95.131.121.65   -j REJECT
$IPT -A FW -d 82.199.80.141   -j REJECT
$IPT -A FW -d 83.133.189.139  -j REJECT
$IPT -A FW -d 85.90.254.45    -j REJECT
$IPT -A FW -d 212.227.67.37   -j REJECT
$IPT -A FW -d 195.20.250.231  -j REJECT
$IPT -A FW -d 46.4.115.113    -j REJECT
$IPT -A FW -d 144.76.67.119   -j REJECT
$IPT -A FW -d 206.191.168.170 -j REJECT
$IPT -A FW -d 46.20.32.75     -j REJECT
$IPT -A FW -d 217.72.250.89   -j REJECT
$IPT -A FW -d 95.172.69.42    -j REJECT
$IPT -A FW -d 217.72.250.84   -j REJECT
$IPT -A FW -d 178.250.0.101   -j REJECT
$IPT -A FW -d 213.203.221.43  -j REJECT
$IPT -A FW -d 178.250.2.77    -j REJECT
$IPT -A FW -d 83.169.54.252   -j REJECT
$IPT -A FW -d 213.203.221.32  -j REJECT
$IPT -A FW -d 217.72.250.66   -j REJECT
$IPT -A FW -d 178.63.153.114  -j REJECT
$IPT -A FW -d 95.131.121.199  -j REJECT
$IPT -A FW -d 93.184.221.133  -j REJECT
$IPT -A FW -d 46.20.32.74     -j REJECT
$IPT -A FW -d 176.9.103.51    -j REJECT
$IPT -A FW -d 85.195.127.21   -j REJECT
$IPT -A FW -d 80.252.91.41    -j REJECT
$IPT -A FW -d 178.250.2.73    -j REJECT
$IPT -A FW -d 85.25.248.94    -j REJECT
$IPT -A FW -d 178.250.2.102   -j REJECT
$IPT -A FW -d 80.190.166.25   -j REJECT
$IPT -A FW -d 88.198.208.110  -j REJECT
$IPT -A FW -d 188.65.74.70    -j REJECT
$IPT -A FW -d 62.141.33.131   -j REJECT
$IPT -A FW -d 82.196.187.209  -j REJECT
$IPT -A FW -d 194.126.239.34  -j REJECT
$IPT -A FW -d 74.119.117.71   -j REJECT
$IPT -A FW -d 91.215.101.185  -j REJECT
$IPT -A FW -d 216.38.172.131  -j REJECT
$IPT -A FW -d 184.168.47.225  -j REJECT
$IPT -A FW -d 54.68.106.202   -j REJECT
$IPT -A FW -d 93.184.220.20   -j REJECT
# ----------------------------------------------------------------------------
