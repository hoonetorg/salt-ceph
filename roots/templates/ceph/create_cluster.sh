#!/bin/sh
subnet=$(ip a | grep 10.8.8.21 | awk '{ print $2 }' | sed 's/\.[0-9]*\//.0\//')
cat << EOF > /etc/ceph/ceph.conf &&
[global]
fsid = {{ fsid }}
osd pool default size = {{ pool_size }}
mon initial members = {{ fqdn }}{%
  for mem in nodes %}{%
    if mem != fqdn %}, {{ mem }}{%
    endif %}{%
  endfor %}
mon host = {{ ip }}
public network = $subnet
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
filestore xattr use omap = true

[mon]
mon data = /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }}
EOF
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *' &&
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow' &&
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring &&
monmaptool --create --add {{ fqdn }} {{ ip }} --fsid {{ fsid }} /tmp/monmap &&
mkdir /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }} &&
ceph-mon --cluster {{ cluster_name }} --mkfs -i {{ fqdn }} --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring &&
touch /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }}/done &&
exit 0
exit 1
