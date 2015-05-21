#!/bin/sh
ceph-disk prepare --cluster {{ cluster_name }} --cluster-uuid {{ fsid }} --fs-type ext4 {{ disk }}
