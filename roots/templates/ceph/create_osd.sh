#!/bin/bash

while getopts ":i:d:c:f:r:h" opt; do
    case $opt in
        i)
            OSD_ID="$OPTARG"
            ;;
        d)
            OSD_DISK="$OPTARG"
            ;;
        c)
            CLUSTER_NAME="$OPTARG"
            ;;
        f)
            FQDN="$OPTARG"
            ;;
        r)
            IDFILE="$OPTARG"
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
    echo "usage: $0 -i OSD_ID -d OSD_DISK -c CLUSTER_NAME -f FQDN"`
    `" [ -r IDFILE ]" > /dev/stderr
    exit $USAGE
fi

if [ -z $IDFILE ]; then
    IDFILE='/var/lib/ceph/osd/id-file'
fi

set -o pipefail
set -e
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG

OSD_UUID=`uuidgen`
ADM_KEY={{ adm_key }}
TMP_CFG="/tmp/${CLUSTER_NAME}.conf.tmp"
echo $TMP_CFG

if [ -f $IDFILE ]; then
  IDL_BAK=1
  cp $IDFILE{,.bak}
fi &&
sgdisk ${OSD_DISK} -n 0:0:10G -n 0
sleep 1 && # wait for /dev/disk/by-partuuid
DATA_PART="${OSD_DISK}2" &&
JRNL_PART=`echo ${OSD_DISK}1 | rev | cut -d '/' -f 1 | rev` &&
echo "jrnl = $JRNL_PART" &&
JRNL_UUID=`ls -l /dev/disk/by-partuuid | grep "$JRNL_PART" | awk '{print $9}'` &&
dd if=/dev/zero of=${OSD_DISK}1 bs=1M count=20
touch $TMP_CFG &&
chmod 400 $TMP_CFG &&
cat /etc/ceph/${CLUSTER_NAME}.conf >> $TMP_CFG &&
echo "[client.admin]" >> $TMP_CFG &&
echo -n "key = " >> $TMP_CFG &&
echo "$ADM_KEY" >> $TMP_CFG &&
echo -n "${OSD_DISK} " >> $IDFILE &&
GEN_ID=$(ceph -c $TMP_CFG osd create $OSD_UUID | tee -a $IDFILE) &&
echo "created osd.$GEN_ID, expected $OSD_ID" &&
[ $GEN_ID == $OSD_ID ] &&
mkfs -t ext4 "$DATA_PART" &&
mkdir "/var/lib/ceph/osd/${CLUSTER_NAME}-${OSD_ID}" &&
mount -o user_xattr "$DATA_PART" \
"/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID" &&
echo "ln -s /dev/disk/by-partuuid/$JRNL_UUID \
/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID/journal" &&
ln -s /dev/disk/by-partuuid/$JRNL_UUID \
/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID/journal &&
ceph-osd -c $TMP_CFG \
--osd-data "/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID" \
--osd-journal "/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID/journal" \
-i $OSD_ID --mkjournal --mkfs --mkkey --osd-uuid $OSD_UUID &&
ceph -c $TMP_CFG \
  auth add osd.$OSD_ID \
  osd 'allow *' \
  mon 'allow profile osd' \
  -i "/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID/keyring" &&
ceph -c $TMP_CFG osd crush add-bucket ${FQDN} host &&
ceph -c $TMP_CFG osd crush move ${FQDN} root=default &&
ceph -c $TMP_CFG osd crush add "osd.$OSD_ID" 2.0 host=${FQDN} &&
umount $DATA_PART

RET=$? CMD=$prev_cmd

if [ $RET -ne 0 ]; then
  # expand variables in the registered command
  FULLCMD=`eval 'eval "echo $CMD"'`
  echo "an error occured ($RET) while running '$FULLCMD'" > /dev/stderr
  echo 'cleaning up...' > /dev/stderr
  if [ ! -z $IDL_BAK ]; then
    cp $IDFILE{.bak,}
  else
    rm -f $IDFILE
  fi
  if mount | grep -q "$DATA_PART "; then
    umount $DATA_PART
  fi
  dd if=/dev/zero of=$DATA_PART bs=1M count=20
  sgdisk -o ${OSD_DISK}
  rm -rvf "/var/lib/ceph/osd/${CLUSTER_NAME}-$OSD_ID"
  if [ ! -z $GEN_ID ]; then
    ceph -c $TMP_CFG osd rm "osd.$GEN_ID"
    ceph -c $TMP_CFG osd crush remove "osd.$GEN_ID"
    ceph -c $TMP_CFG auth del "osd.$GEN_ID"
  fi
else
  echo 'osd has been created successfully'
fi

rm $TMP_CFG
exit $RET
