#!/bin/bash
#ceph-disk prepare --cluster {{ cluster_name }} --cluster-uuid {{ fsid }} --fs-type ext4 {{ disk }}
#ceph-disk activate {{ disk }}1 --activate-key { bootstrap_key }

set -o pipefail
set -e
trap 'prev_cmd=$this_cmd; this_cmd=$BASH_COMMAND' DEBUG

OSD_UUID=`uuidgen`
ADM_KEY={{ adm_key }}

cp /etc/ceph/{{ cluster_name }}.conf{,.bak} &&
if [ -f /var/lib/ceph/osd/id-list ]; then
  IDL_BAK=1
  cp /var/lib/ceph/osd/id-list{,.bak}
fi &&
fdisk {{ disk }} << EOF &&
g
n


+10G
n



w
EOF
DATA_PART="{{ disk }}2" &&
JRNL_PART="{{ disk }}1" &&
JRNL_UUID=`ls -l /dev/disk/by-partuuid | grep "$JRNL_PART" | awk '{print $9}'` &&
TMP_CFG="/tmp/{{ cluster_name }}.conf.tmp" &&
dd if=/dev/zero of={{ disk }}1 bs=1M count=20
touch $TMP_CFG &&
chmod 400 $TMP_CFG &&
cat /etc/ceph/{{ cluster_name }}.conf >> $TMP_CFG &&
echo "[client.admin]" >> $TMP_CFG &&
echo -n "key = " >> $TMP_CFG &&
echo "$ADM_KEY" >> $TMP_CFG &&
echo -n '{{ disk }} ' >> /var/lib/ceph/osd/id-list &&
ceph -c $TMP_CFG osd create >> /var/lib/ceph/osd/id-list &&
OSD_ID=`tail -1 /var/lib/ceph/osd/id-list | awk '{print $2}'` &&
echo "created osd.$OSD_ID" &&
mkdir "/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID" &&
mkfs -t ext4 "$DATA_PART" &&
mount -o user_xattr "$DATA_PART" \
"/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID" &&
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
ceph -c $TMP_CFG osd crush add "osd.$OSD_ID" 1.0 host={{ fqdn }}

RET=$? CMD=$prev_cmd

if [ $RET -ne 0 ]; then
  echo "an error occured while running '$CMD'" > /dev/stderr
  echo 'cleaning up...' > /dev/stderr
  cp /etc/ceph/{{ cluster_name }}.conf{.bak,}
  if [ ! -z $IDL_BAK ]; then
    cp /var/lib/ceph/osd/id-list{.bak,}
  else
    rm -f /var/lib/ceph/osd/id-list
  fi
  if mount | grep -q "$DATA_PART "; then
    umount $DATA_PART
  fi
  dd if=/dev/zero of=$DATA_PART bs=1M count=20
  fdisk {{ disk }} << EOF &&
g
w
EOF
  if [ ! -z $OSD_ID ]; then
    rm -rf "/var/lib/ceph/osd/{{ cluster_name }}-$OSD_ID"
    ceph -c $TMP_CFG osd rm "osd.$OSD_ID"
    ceph -c $TMP_CFG auth del "osd.$OSD_ID"
  fi
else
  echo 'osd has been created successfully'
fi

rm $TMP_CFG
exit $RET
