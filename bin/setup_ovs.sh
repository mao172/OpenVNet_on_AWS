#! /bin/sh

script_dir=$(cd $(dirname $0); pwd)

mac_addr=$1
ip_addr=$2
remote_addr=$3

${script_dir}/create_br0.sh ${mac_addr} ${ip_addr}

${script_dir}/create_ovs.sh brtun

service network restart

br0=br0
tun=brtun

br0_pt_prt=patch10
tun_pt_prt=ptun

ovs-vsctl --may-exist add-port ${br0} ${br0_pt_prt} -- \
  set interface ${br0_pt_prt} type=patch options:peer=${tun_pt_prt}

ovs-vsctl --may-exist add-port ${tun} ${tun_pt_prt} -- \
  set interface ${tun_pt_prt} type=patch options:peer=${br0_pt_prt}


ovs-vsctl --may-exist add-port ${tun} gre-ovr -- \
  set interface gre-ovr type=gre options:remote_ip=${remote_addr}
