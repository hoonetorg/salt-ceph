#!/bin/bash
#ceph-disk prepare --cluster {{ cluster_name }} --cluster-uuid { fsid } --fs-type ext4 {{ disk }}
#ceph-disk activate {{ disk }}1 --activate-key { bootstrap_key }

set -o pipefail
set -e
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG

IDFILE='{{ idfile }}'
OSD_ID='{{ osd_id }}'
OSD_UUID=`uuidgen`
ADM_KEY={{ adm_key }}
TMP_CFG="/tmp/{{ cluster_name }}.conf.tmp"
echo $TMP_CFG

cp /etc/ceph/{{ cluster_name }}.conf{,.bak} &&
if [ -f $IDFILE ]; then
  IDL_BAK=1
  cp $IDFILE{,.bak}
fi &&
fdisk {{ disk }} << EOF &&
g
n


+10G
n



w
EOF
sleep 1 && # wait for /dev/disk/by-partuuid
DATA_PART="{{ disk }}2" &&
JRNL_PART=`echo {{ disk }}1 | rev | cut -d '/' -f 1 | rev` &&
echo "jrnl = $JRNL_PART" &&
JRNL_UUID=`ls -l /dev/disk/by-partuuid | grep "$JRNL_PART" | awk '{print $9}'` &&
dd if=/dev/zero of={{ disk }}1 bs=1M count=20
touch $TMP_CFG &&
chmod 400 $TMP_CFG &&
cat /etc/ceph/{{ cluster_name }}.conf >> $TMP_CFG &&
echo "[client.admin]" >> $TMP_CFG &&
echo -n "key = " >> $TMP_CFG &&
echo "$ADM_KEY" >> $TMP_CFG &&
echo -n '{{ disk }} ' >> $IDFILE &&
GEN_ID=$(ceph -c $TMP_CFG osd create $OSD_UUID | tee -a $IDFILE) &&
echo "created osd.$GEN_ID, expected $OSD_ID" &&
[ $GEN_ID == $OSD_ID ] &&
mkdir "/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID" &&
mkfs -t ext4 "$DATA_PART" &&
mount -o user_xattr "$DATA_PART" \
"/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID" &&
echo "ln -s /dev/disk/by-partuuid/$JRNL_UUID \
/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID/journal" &&
ln -s /dev/disk/by-partuuid/$JRNL_UUID \
/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID/journal &&
ceph-osd -c $TMP_CFG \
--osd-data "/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID" \
--osd-journal "/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID/journal" \
-i $OSD_ID --mkjournal --mkfs --mkkey --osd-uuid $OSD_UUID &&
ceph -c $TMP_CFG \
  auth add osd.$OSD_ID \
  osd 'allow *' \
  mon 'allow profile osd' \
  -i "/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID/keyring" &&
ceph -c $TMP_CFG osd crush add-bucket {{ fqdn }} host &&
ceph -c $TMP_CFG osd crush move {{ fqdn }} root=default &&
ceph -c $TMP_CFG osd crush add "osd.$OSD_ID" 2.0 host={{ fqdn }} &&
umount $DATA_PART

RET=$? CMD=$prev_cmd

if [ $RET -ne 0 ]; then
  # expand variables in the registered command
  FULLCMD=`eval 'eval "echo $CMD"'`
  echo "an error occured while running '$FULLCMD'" > /dev/stderr
  echo 'cleaning up...' > /dev/stderr
  cp /etc/ceph/{{ cluster_name }}.conf{.bak,}
  if [ ! -z $IDL_BAK ]; then
    cp $IDFILE{.bak,}
  else
    rm -f $IDFILE
  fi
  if mount | grep -q "$DATA_PART "; then
    umount $DATA_PART
  fi
  dd if=/dev/zero of=$DATA_PART bs=1M count=20
  fdisk {{ disk }} << EOF &&
g
w
EOF
  rm -rf "/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID"
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
