#!/bin/bash

#not exported
#  description

echo ldapoptions: $@ >&2

ldapsearch $@ -b "ou=machines,dc=net,dc=in,dc=tum,dc=de" cn ipHostNumber macAddress NetInTumIp6 NetInTumBootmode NetInTumPf NetInTumAdditionalHostName

ldapsearch $@ -b "ou=vlans,dc=net,dc=in,dc=tum,dc=de" objectClass NetInTumVlan NetInTumIpPrefix NetInTumAdditionalName NetInTumPf

ldapsearch $@ -b "ou=pfgroups,dc=net,dc=in,dc=tum,dc=de" cn NetInTumPfGroupMember


