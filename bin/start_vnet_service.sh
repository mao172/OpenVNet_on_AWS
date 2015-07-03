#! /bin/sh

PATH=/opt/axsh/openvnet/ruby/bin:${PATH}

initctl start vnet-vnmgr
initctl start vnet-webapi
initctl start vnet-vna
