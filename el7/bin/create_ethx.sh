#! /bin/sh

dev=$1

cat > /etc/sysconfig/network-scripts/ifcfg-${dev} <<EOF
DEVICE=${dev}
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
DEFROUTE=no
EOF

ifup ${dev}

ip addr show dev ${dev}
