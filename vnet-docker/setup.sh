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

run yum -y updatei
if [ $status -ne 0 ]; then
  echo $output >&2
fi

run yum -y install openssh-server openssh-clients
if [ $status -ne 0 ]; then
  echo $output >&2
fi

run sed -ri 's/^#PermitEmptyPasswords no/PermitEmptyPasswords yes/' /etc/ssh/sshd_config
if [ $status -ne 0 ]; then
  echo $output >&2
fi

run sed -ri 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
if [ $status -ne 0 ]; then
  echo $output >&2
fi

run sed -ri 's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
if [ $status -ne 0 ]; then
  echo $output >&2
fi

run passwd -d root
if [ $status -ne 0 ]; then
  echo $output >&2
fi

