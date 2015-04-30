#!/bin/sh

ADM_NODE="ceph-adm-1.infralab.arkena.net"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
	echo "usage: $0 file_roots [adm_node_hostname]" > /dev/stderr
	exit 1
elif [ "$#" -eq 2 ]; then
	ADM_NODE="$2"
fi

FILE_ROOTS=$1
ssh-keygen -q -t rsa -f $FILE_ROOTS/ceph/base/bucket/ssh/$ADM_NODE -N ""
