#! /bin/sh

inetary=($(ip addr show dev br0 | grep 'inet'))
host_ip=$(echo ${inetary[1]} | awk -F '[/]' '{print $1}')
host_nw=$(ip route | grep ${host_ip} | awk '{print $1}')
host_mask=$(echo ${host_nw} | awk -F '[/]' '{print $2}')
host_nw=$(echo ${host_nw} | awk -F '[/]' '{print $1}')

dest=192.168.99.0/24
gw=172.31.32.1.1
if=br0

ip route add ${dest} via ${gw} dev ${if}


dest=${host_nw}/${host_mask}

gw=192.168.99.1

cntnr_lst=($(docker ps | awk '{print $1}' | sed -e '1d'))

for cntnr_id in ${cntnr_lst[@]}
do
  pid=$(docker inspect --format {{.State.Pid}} ${cntnr_id})

  if=$(ip netns exec ${pid} ip route | grep 192.168.99.0 | awk '{print $3}')

  ip netns exec ${pid} ip route add ${dest} via ${gw} dev ${if}
done
