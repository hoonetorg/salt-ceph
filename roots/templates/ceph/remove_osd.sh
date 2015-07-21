#!/bin/bash

while getopts ":i:d:c:f:h" opt; do
    case $opt in
        i)
            OSD_ID="$OPTARG"
            ;;
        d)
            OSD_DISK="$OPTARG"
            ;;
        f)
            FQDN="$OPTARG"
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

if [ -z $USAGE ] && ([ -z $OSD_ID ] || [ -z $OSD_DISK ] ||
    [ -z $FQDN ] || [ -z $CLUSTER_NAME ]); then
    USAGE=1
fi

if [ ! -z $USAGE ]; then
    echo "usage: $0 -i OSD_ID -d OSD_DISK -f FQDN -c CLUSTER_NAME" > /dev/stderr
    exit $USAGE
fi

set -o pipefail
set -e
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG

TMP_CFG="/tmp/${CLUSTER_NAME}.conf.tmp"
ADM_KEY={{ adm_key }}

CMD_RUN=0
touch $TMP_CFG &&
chmod 400 $TMP_CFG &&
cat /etc/ceph/${CLUSTER_NAME}.conf >> $TMP_CFG &&
echo "[client.admin]" >> $TMP_CFG &&
echo -n "key = " >> $TMP_CFG &&
echo "$ADM_KEY" >> $TMP_CFG &&
OSD_WEIGHT=$(ceph -c $TMP_CFG osd tree |
grep "osd.$OSD_ID" | awk '{print $2}') &&
[ -n "$OSD_WEIGHT" ] &&
ceph -c $TMP_CFG osd crush remove osd.$OSD_ID &&
CMD_RUN=`expr $CMD_RUN + 1` &&
ceph -c $TMP_CFG auth del osd.$OSD_ID &&
CMD_RUN=`expr $CMD_RUN + 1` &&
ceph -c $TMP_CFG osd rm $OSD_ID &&
CMD_RUN=`expr $CMD_RUN + 1`

RET=$? CMD=$prev_cmd

if [ $RET -ne 0 ]; then
  # expand variables in the registered command
  FULLCMD=`eval 'eval "echo $CMD"'`
  echo "an error occured ($RET) while running '$FULLCMD'" > /dev/stderr
  echo "trying to restore osd to its previous state" > /dev/stderr
  [ $CMD_RUN -ge 1 ] &&
      ceph -c $TMP_CFG osd crush add "osd.$OSD_ID" $OSD_WEIGHT host=${FQDN}
  [ $CMD_RUN -ge 2 ] &&
      ceph -c $TMP_CFG auth add "osd.$OSD_ID" \
      osd 'allow *' \
      mon 'allow profile osd' \
      -i "/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID/keyring"
else
  echo "osd.$OSD_ID has been removed successfully"
fi

rm $TMP_CFG
exit $RET
