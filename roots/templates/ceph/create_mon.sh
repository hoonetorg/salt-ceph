#!/bin/sh
CFGFILE=/etc/ceph/{{ cluster_name }}.conf
TMPDIR={{ tmpdir }}
mkdir $TMPDIR &&
ceph -c $CFGFILE auth get mon. -o $TMPDIR/mon.keyring &&
ceph -c $CFGFILE mon getmap -o $TMPDIR/monmap &&
ceph-mon -c $CFGFILE -i {{ mon_id }} --mkfs --monmap $TMPDIR/monmap --keyring $TMPDIR/mon.keyring &&
exit 0
exit 1
