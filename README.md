# OpenVNet

## OpenVNetを取り巻く周辺

### OpenFlow

OpenFlowとは、ソフトウエアによってネットワークの構成を行うための技術。
Software Definitions Network(SDN)の技術要素の１つである。
[Open Network Foundation](https://www.opennetworking.org/)によって標準仕様の策定が行われている。

従来のネットワーク機器ではそれぞれの機器が個々に経路制御していたが、
OpenFlowでは経路制御機能を「OpenFlowコントローラ」として分離し、
OpenFlowの規格に準拠（OpenFlowプロトコルでコントローラと対話できる必要がある）した「OpenFlowスイッチ」群を一括管理することができる。

OpenFlowコントローラはソフトウエアで実装され、OpenFlowスイッチはハードウエア（ネットワーク機器）で実現されるが、
ソフトウエアで実装されたスイッチとして、[Open vSwitch](http://openvswitch.org/)などがある。

<参考>
- [5分で絶対に分かるOpenFlow](http://www.atmarkit.co.jp/ait/articles/1112/12/news117_2.html) - @IT
- [ネットワーク管理を大きく変えるOpenFlowとは (1)](http://tech-sketch.jp/2012/04/openflow-1.html) - Teck-Sketch
- [ネットワーク管理を大きく変えるOpenFlowとは (2)](http://tech-sketch.jp/2012/07/openflow2.html) - Teck-Sketch

### Open vSwitch
OSSの仮想スイッチ。XenServer,KVM, VirtualBoxなどの仮想化プラットフォームでも使用されている。
VM（ゲストOS）のネットワークを構成するために使用されるため、ハイパーバイザーの横に位置することが多いが、
Linux OS上で単体で稼動させることも可能。
また、最近ではOpenFlowに対応したハードウエア（ネットワーク機器）に搭載されていることもある。

- [Open vSwitch](http://openvswitch.org/)

### Redis
Key-Valueストア(KVS)を構築することができるソフトウェアの一つ

- [Redisの使い方](http://promamo.com/?p=3358) - 技術の犬小屋


### GRE (Generic Routing Encapsulation)

- [GRE ( Generic Routing Encapsulation ) とは](http://www.infraexpert.com/study/rp8gre.htm)
- [VPN（GREトンネルとルーティングプロトコル 1） CCNP実機で学ぶ](http://atnetwork.info/ccnp4/vpn17.html)
- [[NT]VPN トンネル - GRE プロトコル 47 パケットの説明と使い方](https://support.microsoft.com/ja-jp/kb/241251/ja)
- [OpenvSwitchにGREトンネルを設定](http://alexei-karamazov.hatenablog.com/entry/2013/11/16/180213) - 猫型エンジニアのブログ


## AWS環境を使う
### ソース/宛先チェックの無効化

EC2のインスタンスを選択し、[アクション]-[ネットワーキング]-[送信元/送信先の変更チェック]を選択する。


### AWS のVPC(EC2インスタンス)にENIを追加する

1. EC2の「ネットワークインタフェース」から「ネットワークインタフェースの作成」をする
  - 既に割りあたっているeth0 と同じサブネットを選択する
  - セキュリティグループは作成済みの中から適切なものを選択
2. 作成したeniの設定
  - [アクション]-[ネットワーキング]-[送信元/送信先の変更チェック]を選択し、送信元/送信先チェックを無効にする
2. 作成されたeniを選択し、「アタッチ」する
3. アタッチ先のEC2インスタンスにSSHログイン
  - eth1が追加されていることを確認
```
$ ifconfig -a
```

  - eth1の設定を追加し、upする  

```
$ cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
DEFROUTE=no
EOF

ifup eth1
```

<<参考>>
- [EC2に複数のENIをアタッチする手順と制約（Public-ip,DNSが割当てられなくなる）](http://qiita.com/kaojiri/items/94bc62c7b003367b5e46) - Qiita
- [AWS EC2 で Ping応答を得られるようにする設定](http://www.checksite.jp/aws-ec2-icmp-rule/)
- [VPC で Elastic Network Interface を使用する](http://docs.aws.amazon.com/ja_jp/AmazonVPC/latest/UserGuide/VPC_ElasticNetworkInterfaces.html)  - Amazon.com


### セキュリティグループの設定

- PINGで疎通確認を行うため、ICMPを許可しておく。
- GRE プロトコルの47を許可しておく。

#### インバウンド

- カスタムプロトコル: 47 : すべて
- SSH : TCP : 22
- すべてのICMP : すべて : 該当なし

### 参考
- [openvswitchでVXLAN環境(unicast)を構築する](http://d.hatena.ne.jp/KNOPP/20140901/1409526876)

## OpenVNetの構成要素
- vna
- vnmgr
- webapi

## OpenVNet のセットアップ

### 参考
- [OpenVNet Installation Guide](http://openvnet.org/installation/)
- [OpenVNetとDockerを組み合わせてみるデモ（分散vna）](http://qiita.com/qb0c80aE/items/8d176bdf4d2460849ed9) : Qiita

### セットアップ手順

[インストールガイド](http://openvnet.org/installation/)に従い、以下の順にコマンドを実行していく

```Shell:create_br0.sh
$ curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet.repo
$ curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet-third-party.repo
$ yum install -y epel-release
$ yum install -y openvnet
```

#### Open vSwitchを使って仮想ブリッジを作成する

```
inetary=($(ifconfig eth1 | grep 'inet addr'))

ipaddress=$(echo ${inetary[1]} | awk -F '[: ]' '{print $2}')
netmask=$(echo ${inetary[3]} | awk -F '[: ]' '{print $2}')

infoary=($(ifconfig eth1 | grep 'HWaddr'))
macaddress=${infoary[4]}

cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br0
BOOTPROTO=none
ONBOOT=yes
HOTPLUG=no
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
DEVICE=br0
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
IPADDR=${ipaddress}
NETMASK=${netmask}
HOTPLUG=no
OVS_EXTRA="
 set bridge     \${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     \${DEVICE} other_config:disable-in-band=true --
 set bridge     \${DEVICE} other-config:datapath-id=0000$(echo ${macaddress} | tr -d ':') --
 set bridge     \${DEVICE} other-config:hwaddr=${macaddress} --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

service openvswitch start
ifup br0 eth1

service network restart
```

#### OVSを使ったネットワーク構成
下図のように構成する。
![OVSを使ったネットワーク構成](http://bl.ocks.org/mao172/raw/b6660f9cb1b73a0b600d/network_01.png)

sv1,sv2側のGRETapを作成するシェルスクリプト
```
#! /bin/sh
# Usage:
#  create_gretap NAME REMOTE_ADDR LOCAL_ADDR VIRTUAL_ADDR

name=${1}
remote_addr=${2}
local_addr=${3}
virtual_addr=${4}

ip link add ${name} type gretap remote ${remote_addr} local ${local_addr}
ip addr add ${virtual_addr} dev ${name}
ip link set ${name} up
ip link set ${name} mtu 1450

ifconfig ${name}
```

sv1,sv2にログインして実行する。

sv0にログインし、OVS側のGREポートを`ovs-vsctl`コマンドを使用して作成する
```
$ ovs-vsctl add-port br0 ${name} -- \
    set interface ${name} \
    type=gre \
    options:local=${local_addr} \
    options:remote_ip=${remote_addr} \
    options:pmtud=true
```

#### Redisの設定と起動

```
$ sed -i -E 's/bind [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/bind 0.0.0.0/g' /etc/redis.conf
$ service redis start
```

#### Databaseのセットアップ

```
# Launch mysql server.
service mysqld start

# To automatically launch the mysql server at boot, execute the following command.
chkconfig mysqld on

# Set PATH environment variable as following since the OpenVNet uses its own ruby binary.
PATH=/opt/axsh/openvnet/ruby/bin:${PATH}

# Create database
cd /opt/axsh/openvnet/vnet
bundle exec rake db:create
bundle exec rake db:init
```

#### OpenVNetの設定

```
# Start vnmgr and webapi.
initctl start vnet-vnmgr
initctl start vnet-webapi

# Datapath

datapath_id=$(echo $(cat /etc/sysconfig/network-scripts/ifcfg-br0 | grep datapath-id= | awk -F '[:=-]' '{print $5}'))

name=${1}
node_id=${2}
network_addr=${3}

if [ "${name}" == "" ]; then
  name="test1"
fi

if [ "${node_id}" == "" ]; then
  node_id="vna"
fi

if [ "${network_addr}" == "" ]; then
  network_addr="10.0.0.0"
fi

vnctl datapaths add --uuid dp-${name} --display-name ${name} --dpid ${datapath_id} --node-id ${node_id}


# Network

vnctl networks add --uuid nw-${name} --display-name ${name}-net --ipv4-network ${network_addr} --ipv4-prefix 24 --network-mode virtual


# Interface
#

vnctl interfaces add --uuid if-inst1 \
    --mode vif --owner-datapath-uuid dp-${name} \
    --mac-address EE:99:D5:67:FD:52 \
    --network-uuid nw-${name} \
    --ipv4-address 10.0.0.1 \
    --port-name tap1
vnctl interfaces add --uuid if-inst2 \
    --mode vif --owner-datapath-uuid dp-${name} \
    --mac-address 2A:27:6E:63:5E:E5 \
    --network-uuid nw-${name} \
    --ipv4-address 10.0.0.2 \
    --port-name tap2

```

#### サービスの起動
```
initctl start vnet-vnmgr
initctl start vnet-webapi
initctl start vnet-vna
```


* これだとeth1にきたGREのパケットがdropされてしまい、疎通が取れなくなる。
  - => br0 にIPを振らない、eth1をつながない
  - => eth1をGRE専用にする（いったん）

* P2Vどうしよう・・・
