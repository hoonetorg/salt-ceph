#!/bin/sh
fdisk {{ disk }} << EOF
g
w
EOF
ceph-disk prepare --cluster {{ cluster_name }} --cluster-uuid {{ fsid }} --fs-type ext4 {{ disk }}
ceph-disk activate {{ disk }}1 --activate-key {{ bootstrap_key }}
