#! /bin/sh

if [ -f /etc/redhat-release ];then
  version=$(rpm -qf --queryformat="%{VERSION}" /etc/redhat-release)
fi

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

disabled_service() {
  svcname=$1

  case ${version} in
    '6' )
      run service iptables status
      if [ $status -eq 0 ]; then
        service ${svcname} stop
        /sbin/chkconfig ${svcname} off
      fi
      ;;
    '7' )
      run systemctl status ${svcname}
      if [ "$status" -eq 0 ]; then
        systemctl stop ${svcname}
        systemctl disable ${svcname}
      fi
      ;;
  esac
}

run yum update -y
if [ $status -ne 0 ]; then
  echo "$output" >&2
fi

# disabled iptables
disabled_service iptables

# disabled firewalld
disabled_service  firewalld

# disabled SELinux

run getenforce

if [ "$output" == "Enforcing" ]; then
  sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  reboot
  exit
fi
