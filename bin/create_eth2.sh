#! /bin/sh

cat > /etc/sysconfig/network-scripts/ifcfg-eth2 <<EOF
DEVICE=eth2
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
DEFROUTE=no
EOF

ifup eth2

ifconfig eth2
