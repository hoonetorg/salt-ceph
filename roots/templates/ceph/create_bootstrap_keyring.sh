#!/bin/bash

while getopts ":n:c:h" opt; do
    case $opt in
        n)
            NODETYPE="$OPTARG"
            ;;
        c)
            CLUSTER_NAME="$OPTARG"
            ;;
        h)
            USAGE=0
            ;;
        ?)
            USAGE=1
            ;;
    esac
done

if [ -z $USAGE ] && ([ -z $NODETYPE ] || [ -z $CLUSTER_NAME ]); then
    USAGE=1
fi

if [ ! -z $USAGE ]; then
    echo "usage: $0 -n NODETYPE -c CLUSTER_NAME" > /dev/stderr
    exit $USAGE
fi

set -o pipefail
set -e
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG

ceph-authtool \
    -n client.bootstrap-${NODETYPE} \
    --cap mon "allow profile bootstrap-${NODETYPE}" \
    -C /var/lib/ceph/bootstrap-${NODETYPE}/${CLUSTER_NAME}.keyring \
    --gen-key &&
ceph \
    -c /etc/ceph/${CLUSTER_NAME}.conf \
    auth add "client.bootstrap-${NODETYPE}" \
    -i /var/lib/ceph/bootstrap-${NODETYPE}/${CLUSTER_NAME}.keyring

RET=$? CMD=$prev_cmd

if [ $RET -ne 0 ]; then
  # expand variables in the registered command
  FULLCMD=`eval 'eval "echo $CMD"'`
  echo "an error occured ($RET) while running '$FULLCMD'" > /dev/stderr
fi

exit $RET
