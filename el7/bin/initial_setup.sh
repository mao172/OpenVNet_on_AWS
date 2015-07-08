#! /bin/sh

run() {
  [[ ! "$-" =~ e ]] || e=1
  [[ ! "$-" =~ E ]] || E=1
  [[ ! "$-" =~ T ]] || T=1

  set +e
  set +E
  set +T

  output="$("$@" 2>&1)"
  status="$?"
  oldIFS=$IFS
  IFS=$'\n' lines=($output)

  IFS=$oldIFS
  [ -z "$e" ] || set -e
  [ -z "$E" ] || set -E
  [ -z "$T" ] || set -T
}

yum update -y


# disabled SELinux

run getenforce

if [ "$output" == "Enforcing" ]; then
  sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  reboot
fi

# disabled iptables

run systemctl status iptables

if [ "$status" -eq 0 ]; then
  systemctl stop iptables
  systemctl disable iptables
fi

# disabled firewalld

run systemctl status firewalld

if [ "$status" -eq 0 ]; then
  systemctl stop firewalld
  systemctl disable firewalld
fi
