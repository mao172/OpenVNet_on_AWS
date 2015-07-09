#! /bin/sh

bridge=$1

virtual_mask=24

rm -r -f /var/run/netns/

mkdir -p /var/run/netns/

if [ -p /dev/stdin ]; then
  input=$(cat -)
  oldIFS=$IFS
  IFS=$'\n'
  lines=($input)

  for infc in ${lines[@]}
  do
    image=$(echo ${infc} | awk '{print $1}')
    name=$(echo ${infc} | awk '{print $2}')
    bif=$(echo ${infc} | awk '{print $3}')
    cif=$(echo ${infc} | awk '{print $4}')
    ip=$(echo ${infc} | awk '{print $5}')
    mac=$(echo ${infc} | awk '{print $6}')

    id=$(docker run -h ${name} --net="none" -i -t -d ${image} /bin/bash)
    pid=$(docker inspect --format {{.State.Pid}} ${id})

    ln -s /proc/${pid}/ns/net /var/run/netns/${pid}

    ip link add ${bif} type veth peer name ${cif}

    ip link set ${bif} up
    ovs-vsctl add-port ${bridge} ${bif}

    ip link set ${cif} netns ${pid}
    ip netns exec ${pid} ip link set dev ${cif} address ${mac}
    ip netns exec ${pid} ip addr add ${ip}/${virtual_mask} dev ${cif}
    ip netns exec ${pid} ip link set ${cif} up

    gw=${ip}

    ip netns exec ${pid} ip route add ${dest} via ${gw} dev ${cif}
  done

  IFS=$oldIFS
fi
