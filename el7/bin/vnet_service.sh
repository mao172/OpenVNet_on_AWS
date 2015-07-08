#! /bin/sh

cd /opt/axsh/openvnet/vnet/

cat <<_EOF_ > ./bin/vnet-vnmgr
#!/bin/bash

NAME=vnmgr

[ -f /etc/default/vnet-\${NAME} ] && . /etc/default/vnet-\${NAME}
export LOG_DIRECTORY

[ -d "\${LOG_DIRECTORY}" ] || {
  mkdir \${LOG_DIRECTORY}
}

[ -d "\${VNET_ROOT}" ] || {
  logger "no such directory: \${VNET_ROOT}"
  exit 1
}
cd \${VNET_ROOT}/vnet/

bundle exec ./bin/\${NAME} \
    >> \${LOG_DIRECTORY}/\${NAME}.log 2>&1
_EOF_

cat <<_EOF_ > ./bin/vnet-webapi
#!/bin/bash

NAME=webapi

[ -f /etc/default/vnet-\${NAME} ] && . /etc/default/vnet-\${NAME}
export LOG_DIRECTORY

[ -d "\${LOG_DIRECTORY}" ] || {
  mkdir \${LOG_DIRECTORY}
}

[ -d "\${VNET_ROOT}" ] || {
  logger "no such directory: \${VNET_ROOT}"
  exit 1
}
cd \${VNET_ROOT}/vnet/

bundle exec unicorn \
 -o \${BIND_ADDR:-0.0.0.0} \
 -p \${PORT:-9090} \
 ./rack/config-\${NAME}.ru \
    >> \${LOG_DIRECTORY}/\${NAME}.log 2>&1
_EOF_

cat <<_EOF_ > ./bin/vnet-vna
#!/bin/bash

NAME=vna

[ -f /etc/default/vnet-\${NAME} ] && . /etc/default/vnet-\${NAME}
export LOG_DIRECTORY

[ -d "\${LOG_DIRECTORY}" ] || {
  mkdir \${LOG_DIRECTORY}
}

[ -d "\${VNET_ROOT}" ] || {
  logger "no such directory: \${VNET_ROOT}"
  exit 1
}
cd \${VNET_ROOT}/vnet/

bundle exec ./bin/\${NAME} \
    >> \${LOG_DIRECTORY}/\${NAME}.log 2>&1
_EOF_

chmod +x bin/vnet-*


cat <<_EOF_ >  /etc/systemd/system/vnet-vnmgr.service

[Unit]
Description=OpenVNet Manager Service
After=openvswitch.service redis.service mysql.service
Requires=openvswitch.service redis.service mysql.service

[Service]
Type=simple
ExecStart=/opt/axsh/openvnet/vnet/bin/vnet-vnmgr

[Install]
WantedBy=multi-user.target
_EOF_

cat <<_EOF_ >  /etc/systemd/system/vnet-webapi.service

[Unit]
Description=OpenVNet WebAPI Service
After=openvswitch.service redis.service mysql.service
Requires=openvswitch.service redis.service mysql.service

[Service]
Type=simple
ExecStart=/opt/axsh/openvnet/vnet/bin/vnet-webapi

[Install]
WantedBy=multi-user.target
_EOF_

cat <<_EOF_ >  /etc/systemd/system/vnet-vna.service

[Unit]
Description=OpenVNet Agent Service
After=openvswitch.service redis.service mysql.service
Requires=openvswitch.service redis.service mysql.service

[Service]
Type=simple
ExecStart=/opt/axsh/openvnet/vnet/bin/vnet-vna

[Install]
WantedBy=multi-user.target
_EOF_

