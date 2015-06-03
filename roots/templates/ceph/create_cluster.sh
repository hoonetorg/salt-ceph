#!/bin/sh
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *' &&
ceph-authtool --create-keyring /var/lib/ceph/admin/{{ cluster_name }}.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow' &&
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/admin/{{ cluster_name }}.keyring &&
monmaptool --create --add {{ fqdn }} {{ ip }} --fsid {{ fsid }} /tmp/monmap &&
mkdir -p /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }} &&
ceph-mon --cluster {{ cluster_name }} --mkfs -i {{ fqdn }} --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring &&
touch /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }}/done &&
rm -v /tmp/ceph.mon.keyring &&
exit 0
exit 1
