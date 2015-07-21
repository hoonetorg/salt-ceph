#!/bin/bash

while getopts ":i:d:c:h" opt; do
    case $opt in
        i)
            MON_ID="$OPTARG"
            ;;
        d)
            TMP_DIR="$OPTARG"
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

if [ -z $USAGE ] && ([ -z $MON_ID ] || [ -z $CLUSTER_NAME ] ||
    [ -z $TMP_DIR ]); then
    USAGE=1
fi

if [ ! -z $USAGE ]; then
    echo "usage: $0 -i MON_ID -d TMP_DIR -c CLUSTER_NAME" > /dev/stderr
    exit $USAGE
fi

set -o pipefail
set -e
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG

CFGFILE=/etc/ceph/${CLUSTER_NAME}.conf
TMPDIR=${TMP_DIR}
mkdir $TMPDIR &&
ceph -c $CFGFILE auth get mon. -o $TMPDIR/mon.keyring &&
ceph -c $CFGFILE mon getmap -o $TMPDIR/monmap &&
ceph-mon -c $CFGFILE -i ${MON_ID} --mkfs --monmap $TMPDIR/monmap --keyring $TMPDIR/mon.keyring &&
exit 0

RET=$? CMD=$prev_cmd

if [ $RET -ne 0 ]; then
  # expand variables in the registered command
  FULLCMD=`eval 'eval "echo $CMD"'`
  echo "an error occured ($RET) while running '$FULLCMD'" > /dev/stderr
fi

exit $RET
