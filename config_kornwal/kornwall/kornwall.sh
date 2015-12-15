#!/bin/bash
# KoRnwall by KoRny 2006

DIR="/opt"

. $DIR/kornwall/config/config
. $DIR/kornwall/config/ports
. $DIR/kornwall/config/modules


case $1 in
	start | START)
		echo "starting Firewall"
		. $DIR/kornwall/config/startconf
		## alles alte löschen
		$IPTABLES -F
		$IPTABLES -X
		$IPTABLES -P INPUT DROP
		$IPTABLES -P FORWARD DROP
		$IPTABLES -P OUTPUT DROP		
		$IPTABLES -t nat -F
		$IPTABLES -t nat -X	
		$IPTABLES -t nat -P PREROUTING ACCEPT
		$IPTABLES -t nat -P POSTROUTING ACCEPT
		$IPTABLES -t nat -P OUTPUT ACCEPT
		$IPTABLES -t mangle -F
		$IPTABLES -t mangle -X
		
		#Neue Chains
		$IPTABLES -N tcp_packets_out
		$IPTABLES -N tcp_packets_in

		$IPTABLES -N udp_packets_in
		$IPTABLES -N udp_packets_out

		$IPTABLES -N icmp_packets_out
		$IPTABLES -N icmp_packets_in

		if [ $DROP_INVALID == true ] ;then 
			$IPTABLES -A INPUT -m state --state INVALID -j LOG --log-prefix "dropped INVALID IN: "
			$IPTABLES -A INPUT -m state --state INVALID -j DROP
			$IPTABLES -A OUTPUT -m state --state INVALID -j LOG --log-prefix "dropped INVALID OUT: "
			$IPTABLES -A OUTPUT -m state --state INVALID -j DROP
		fi



		# bestehende TCP Verbindungen durchlassen, sonst in die unterketten
		#$IPTABLES -A INPUT -p TCP -m state --state $ESTABLISHED -j ACCEPT #in den einzellnenen Services konfiguriert 
		#$IPTABLES -A OUTPUT -p TCP -m state --state $ESTABLISHED -j ACCEPT
		$IPTABLES -A INPUT -p TCP -d $LAN_IP -j tcp_packets_in #Regeln für TCP Packete
		$IPTABLES -A OUTPUT -p TCP -s $LAN_IP -j tcp_packets_out #Regeln für TCP Packete

		# bestehende UDP Verbindungen durchlassen, sonst in die unterke
		#$IPTABLES -A INPUT -p UDP -m state --state $ESTABLISHED -j ACCEPT
		#$IPTABLES -A OUTPUT -p UDP -m state --state $ESTABLISHED -j ACCEPT
		$IPTABLES -A INPUT -p UDP -d $LAN_IP -j udp_packets_in
		$IPTABLES -A OUTPUT -p UDP -s $LAN_IP -j udp_packets_out 

		# ICMP Unterketten
		$IPTABLES -A INPUT -p ICMP -d $LAN_IP -j icmp_packets_in
		$IPTABLES -A OUTPUT -p ICMP -s $LAN_IP -j icmp_packets_out



		
		echo "Folgende Dienste wurden erlaubt:"
		echo ""

		if [ $LOOPBACK == true ] ;then
			echo "LOOPBACK"
			. $DIR/kornwall/services/loopback
		fi


		if [ $DNS == true ] ;then
			echo 'DNS (deine DNS-Server stehen in /etc/resolv.conf man tippt ja www.google.de und nicht 216.239.57.104)'
			. $DIR/kornwall/services/dns
		fi


		if [ $HTTP == true ] ;then
			echo "HTTP"
			. $DIR/kornwall/services/http
		fi


		if [ $HTTPS == true ] ;then
			echo "HTTPS"
			. $DIR/kornwall/services/https
		fi


		if [ $UDP_LAN_BROADCAST == true ] ;then
			echo "Broadcasts (udp) from $LAN_IP_RANGE"
			. $DIR/kornwall/services/udp_lan_broadcast
		else
			$IPTABLES -A INPUT -p UDP -d $LAN_BROADCAST -s $LAN_IP_RANGE -j DROP
			echo "Note: Dropped broadcasts (udp) from $LAN_IP_RANGE will NOT be logged"
		fi


		if [ $UDP_LAN_BROADCAST_SELF == true ] ;then
			echo "Broadcasts (udp) from $LAN_IP"
			. $DIR/kornwall/services/selfhosted/udp_lan_broadcast
		fi


		if [ $SSH_SELF == true ] ;then
			echo "SSH"
			. $DIR/kornwall/services/selfhosted/ssh
		fi


		if [ $FTP == true ] ;then
			echo "FTP"
			. $DIR/kornwall/services/ftp
		fi



		if [ $ICMP_echo_request == true ] ;then
			. $DIR/kornwall/services/icmp/echo_request
			echo "ICMP_echo_request"
		fi

		if [ $ICMP_source_quench_in == true ] ;then
			. $DIR/kornwall/services/icmp/source_quench_in
			echo "ICMP_source_quench_in"
		fi

		if [ $ICMP_source_quench_out == true ] ;then
			. $DIR/kornwall/services/icmp/source_quench_out
			echo "ICMP_source_quench_out"
		fi




		$IPTABLES -A udp_packets_in -j LOG --log-prefix "dropped IN UDP: "
		$IPTABLES -A udp_packets_in -j DROP

		$IPTABLES -A udp_packets_out -j LOG --log-prefix "dropped OUT UDP: "
		$IPTABLES -A udp_packets_out -j DROP


		$IPTABLES -A tcp_packets_in -j LOG --log-prefix "dropped IN TCP: "
		$IPTABLES -A tcp_packets_in -j DROP

		$IPTABLES -A tcp_packets_out -j LOG --log-prefix "dropped OUT TCP: "
		$IPTABLES -A tcp_packets_out -j DROP


		$IPTABLES -A icmp_packets_in -j LOG --log-prefix "dropped IN ICMP: "
		$IPTABLES -A icmp_packets_in -j DROP

		$IPTABLES -A icmp_packets_out -j LOG --log-prefix "dropped OUT ICMP: "
		$IPTABLES -A icmp_packets_out -j DROP


		$IPTABLES -A INPUT -j LOG --log-prefix "dropped IN: "
		$IPTABLES -A INPUT -j DROP
		$IPTABLES -A OUTPUT -j LOG --log-prefix "dropped OUT: "
		$IPTABLES -A OUTPUT -j DROP

		echo "" > /var/log/firewall
		echo "Gestartet: $(date)" > /var/log/firewall
		
		
	;;
	stop | STOP)
		echo "stopping firewall"
		$IPTABLES -F
		$IPTABLES -X
		$IPTABLES -P INPUT ACCEPT
		$IPTABLES -P FORWARD ACCEPT
		$IPTABLES -P OUTPUT ACCEPT
		echo "stopped"
	;;
	*)
		echo "start or stop parameter missing"
	;;
esac




