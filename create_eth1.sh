#! /bin/sh

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
DEFROUTE=no
EOF

ifup eth1

ifconfig eth1
