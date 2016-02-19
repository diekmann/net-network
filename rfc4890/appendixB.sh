#!/bin/bash
#
# RFC 4890            ICMPv6 Filtering Recommendations            May 2007
#

# Set of prefixes on the trusted ("inner") side of the firewall
export INNER_PREFIXES="2001:DB8:85::/60"
# Set of hosts providing services so that they can be made pingable
export PINGABLE_HOSTS="2001:DB8:85::/64"
# Configuration option: Change this to 1 if errors allowed only for
# existing sessions
export STATE_ENABLED=0
# Configuration option: Change this to 1 if messages to/from link
# local addresses should be filtered.
# Do not use this if the firewall is a bridge.
# Optional for firewalls that are routers.
export FILTER_LINK_LOCAL_ADDRS=0
# Configuration option: Change this to 0 if the site does not support
# Mobile IPv6 Home Agents - see Appendix A.14
export HOME_AGENTS_PRESENT=1
# Configuration option: Change this to 0 if the site does not support
# Mobile IPv6 mobile nodes being present on the site -
# see Appendix A.14
export MOBILE_NODES_PRESENT=1

ip6tables -N icmpv6-filter
ip6tables -A FORWARD -p icmpv6 -j icmpv6-filter

# Match scope of src and dest else deny
# This capability is not provided for in base ip6tables functionality
# An extension (agr) exists which may support it.
#@TODO@


# ECHO REQUESTS AND RESPONSES
# ===========================

# Allow outbound echo requests from prefixes which belong to the site
for inner_prefix in $INNER_PREFIXES
do
  ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
        --icmpv6-type echo-request -j ACCEPT
done

# Allow inbound echo requests towards only predetermined hosts
for pingable_host in $PINGABLE_HOSTS
do
  ip6tables -A icmpv6-filter -p icmpv6 -d $pingable_host \
        --icmpv6-type echo-request -j ACCEPT
done

if [ "$STATE_ENABLED" -eq "1" ]
then
  # Allow incoming and outgoing echo reply messages
  # only for existing sessions
  ip6tables -A icmpv6-filter -m state -p icmpv6 \
        --state ESTABLISHED,RELATED --icmpv6-type \
      echo-reply -j ACCEPT
else
  # Allow both incoming and outgoing echo replies
  for pingable_host in $PINGABLE_HOSTS
  do
    # Outgoing echo replies from pingable hosts
    ip6tables -A icmpv6-filter -p icmpv6 -s $pingable_host \
        --icmpv6-type echo-reply -j ACCEPT
  done
  # Incoming echo replies to prefixes which belong to the site
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
        --icmpv6-type echo-reply -j ACCEPT
  done
fi

# Deny icmps to/from link local addresses
# If the firewall is a router:
#    These rules should be redundant as routers should not forward
#    link local addresses but to be sure...
# DO NOT ENABLE these rules if the firewall is a bridge
if [ "$FILTER_LINK_LOCAL_ADDRS" -eq "1" ]
then
  ip6tables -A icmpv6-filter -p icmpv6 -d fe80::/10 -j DROP
  ip6tables -A icmpv6-filter -p icmpv6 -s fe80::/10 -j DROP
fi

# Drop echo replies which have a multicast address as a
# destination
ip6tables -A icmpv6-filter -p icmpv6 -d ff00::/8 \
        --icmpv6-type echo-reply -j DROP

# DESTINATION UNREACHABLE ERROR MESSAGES
# ======================================

if [ "$STATE_ENABLED" -eq "1" ]
then
  # Allow incoming destination unreachable messages
  # only for existing sessions
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -m state -p icmpv6 \
         -d $inner_prefix \
         --state ESTABLISHED,RELATED --icmpv6-type \
         destination-unreachable -j ACCEPT
  done
else
  # Allow incoming destination unreachable messages
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type destination-unreachable -j ACCEPT
  done
fi

# Allow outgoing destination unreachable messages
for inner_prefix in $INNER_PREFIXES
do
  ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type destination-unreachable -j ACCEPT
done

# PACKET TOO BIG ERROR MESSAGES
# =============================

if [ "$STATE_ENABLED" -eq "1" ]
then
  # Allow incoming Packet Too Big messages
  # only for existing sessions
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -m state -p icmpv6 \
         -d $inner_prefix \
         --state ESTABLISHED,RELATED \
         --icmpv6-type packet-too-big \
         -j ACCEPT
  done
else
  # Allow incoming Packet Too Big messages
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type packet-too-big -j ACCEPT
  done
fi

# Allow outgoing Packet Too Big messages
for inner_prefix in $INNER_PREFIXES
do
  ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type packet-too-big -j ACCEPT
done

# TIME EXCEEDED ERROR MESSAGES
# ============================

if [ "$STATE_ENABLED" -eq "1" ]
then
  # Allow incoming time exceeded code 0 messages
  # only for existing sessions
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -m state -p icmpv6 \
         -d $inner_prefix \
         --state ESTABLISHED,RELATED --icmpv6-type packet-too-big \
         -j ACCEPT
  done
else
  # Allow incoming time exceeded code 0 messages
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type ttl-zero-during-transit -j ACCEPT
  done
fi

#@POLICY@
# Allow incoming time exceeded code 1 messages
for inner_prefix in $INNER_PREFIXES
do
ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type ttl-zero-during-reassembly -j ACCEPT
done

# Allow outgoing time exceeded code 0 messages
for inner_prefix in $INNER_PREFIXES
do
ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type ttl-zero-during-transit -j ACCEPT
done

#@POLICY@
# Allow outgoing time exceeded code 1 messages
for inner_prefix in $INNER_PREFIXES
do
ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type ttl-zero-during-reassembly -j ACCEPT
done


# PARAMETER PROBLEM ERROR MESSAGES
# ================================

if [ "$STATE_ENABLED" -eq "1" ]
then
  # Allow incoming parameter problem code 1 and 2 messages
  # for an existing session
  for inner_prefix in $INNER_PREFIXES
  do
    ip6tables -A icmpv6-filter -m state -p icmpv6 \
         -d $inner_prefix \
         --state ESTABLISHED,RELATED --icmpv6-type \
         unknown-header-type \
         -j ACCEPT
    ip6tables -A icmpv6-filter -m state -p icmpv6 \
         -d $inner_prefix \
         --state ESTABLISHED,RELATED \
         --icmpv6-type unknown-option \
         -j ACCEPT
  done
fi

# Allow outgoing parameter problem code 1 and code 2 messages
for inner_prefix in $INNER_PREFIXES
do
  ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type unknown-header-type -j ACCEPT
  ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type unknown-option -j ACCEPT
done

#@POLICY@
# Allow incoming and outgoing parameter
# problem code 0 messages
for inner_prefix in $INNER_PREFIXES
do
  ip6tables -A icmpv6-filter -p icmpv6 \
         --icmpv6-type bad-header \
         -j ACCEPT
done

# NEIGHBOR DISCOVERY MESSAGES
# ===========================

# Drop NS/NA messages both incoming and outgoing
ip6tables -A icmpv6-filter -p icmpv6 \
         --icmpv6-type neighbor-solicitation -j DROP
ip6tables -A icmpv6-filter -p icmpv6 \
         --icmpv6-type neighbor-advertisement -j DROP

# Drop RS/RA messages both incoming and outgoing
ip6tables -A icmpv6-filter -p icmpv6 \
         --icmpv6-type router-solicitation -j DROP
ip6tables -A icmpv6-filter -p icmpv6 \
         --icmpv6-type router-advertisement -j DROP

# Drop Redirect messages both incoming and outgoing
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type redirect -j DROP

# MLD MESSAGES
# ============

# Drop incoming and outgoing
# Multicast Listener queries (MLDv1 and MLDv2)
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type 130 -j DROP

# Drop incoming and outgoing Multicast Listener reports (MLDv1)
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type 131 -j DROP

# Drop incoming and outgoing Multicast Listener Done messages (MLDv1)
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type 132 -j DROP

# Drop incoming and outgoing Multicast Listener reports (MLDv2)
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type 143 -j DROP

# ROUTER RENUMBERING MESSAGES
# ===========================

# Drop router renumbering messages
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type 138 -j DROP

# NODE INFORMATION QUERIES
# ========================

# Drop node information queries (139) and replies (140)
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type 139 -j DROP
ip6tables -A icmpv6-filter -p icmpv6 --icmpv6-type 140 -j DROP


# MOBILE IPv6 MESSAGES
# ====================

# If there are mobile ipv6 home agents present on the
# trusted side allow
if [ "$HOME_AGENTS_PRESENT" -eq "1" ]
then
  for inner_prefix in $INNER_PREFIXES
  do
    #incoming Home Agent address discovery request
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type 144 -j ACCEPT
    #outgoing Home Agent address discovery reply
    ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type 145 -j ACCEPT
    #incoming Mobile prefix solicitation
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type 146 -j ACCEPT
    #outgoing Mobile prefix advertisement
    ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type 147 -j ACCEPT
  done
fi

# If there are roaming mobile nodes present on the
# trusted side allow
if [ "$MOBILE_NODES_PRESENT" -eq "1" ]
then
  for inner_prefix in $INNER_PREFIXES
  do
    #outgoing Home Agent address discovery request
    ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type 144 -j ACCEPT
    #incoming Home Agent address discovery reply
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type 145 -j ACCEPT
    #outgoing Mobile prefix solicitation
    ip6tables -A icmpv6-filter -p icmpv6 -s $inner_prefix \
         --icmpv6-type 146 -j ACCEPT
    #incoming Mobile prefix advertisement
    ip6tables -A icmpv6-filter -p icmpv6 -d $inner_prefix \
         --icmpv6-type 147 -j ACCEPT
  done
fi

# DROP EVERYTHING ELSE
# ====================

ip6tables -A icmpv6-filter -p icmpv6 -j DROP

