#!/bin/sh
ceph-authtool -n client.bootstrap-{{ nodetype }} --cap mon 'allow profile bootstrap-{{ nodetype }}' -C /var/lib/ceph/bootstrap-{{ nodetype }}/{{ cluster_name }}.keyring --gen-key &&
ceph -c /etc/ceph/{{ cluster_name }}.conf auth add 'client.bootstrap-{{ nodetype }}' -i /var/lib/ceph/bootstrap-{{ nodetype }}/{{ cluster_name }}.keyring
