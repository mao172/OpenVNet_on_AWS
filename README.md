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

## AWS のVPC(EC2インスタンス)にENIを追加する

1. EC2の「ネットワークインタフェース」から「ネットワークインタフェースの作成」をする
  - 既に割りあたっているeth0 と同じサブネットを選択する
  - セキュリティグループは作成済みの中から適切なものを選択
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

## OpenVNetの構成要素
- vna
- vnmgr
- webapi
- vnctl ???

## OpenVNet のセットアップ

### 参考
- [OpenVNet Installation Guide](http://openvnet.org/installation/)
- [OpenVNetとDockerを組み合わせてみるデモ（分散vna）](http://qiita.com/qb0c80aE/items/8d176bdf4d2460849ed9) : Qiita

### セットアップ手順

[インストールガイド](http://openvnet.org/installation/)に従い、以下の順位コマンドを実行していく

```
$ curl -o /etc/yum.repos.d/openvnet.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet.repo
$ curl -o /etc/yum.repos.d/openvnet-third-party.repo -R https://raw.githubusercontent.com/axsh/openvnet/master/deployment/yum_repositories/stable/openvnet-third-party.repo
$ yum install -y epel-release
$ yum install -y openvnet
```

Open vSwitchを使って仮想ブリッジを作成する

```
$ cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
DEVICE=br0
DEVICETYPE=ovs
TYPE=OVSBridge
ONBOOT=yes
BOOTPROTO=static
HOTPLUG=no
OVS_EXTRA="
 set bridge     \${DEVICE} protocols=OpenFlow10,OpenFlow12,OpenFlow13 --
 set bridge     \${DEVICE} other_config:disable-in-band=true --
 set bridge     \${DEVICE} other-config:datapath-id=0000aaaaaaaaaaaa --
 set bridge     \${DEVICE} other-config:hwaddr=02:01:00:00:00:01 --
 set-fail-mode  \${DEVICE} standalone --
 set-controller \${DEVICE} tcp:127.0.0.1:6633
"
EOF

$ service openvswitch start
$ ifup br0
```

Redisの設定と起動

```
$ sed -i -E 's/bind [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/bind 0.0.0.0/g' /etc/redis.conf
$ service redis start
```
