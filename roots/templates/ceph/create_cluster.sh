#!/bin/bash

while getopts ":i:d:c:f:h" opt; do
    case $opt in
        i)
            MON_IP="$OPTARG"
            ;;
        d)
            FSID="$OPTARG"
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

if [ -z $USAGE ] && ([ -z $MON_IP ] || [ -z $FSID ] ||
    [ -z $FQDN ] || [ -z $CLUSTER_NAME ]); then
    USAGE=1
fi

if [ ! -z $USAGE ]; then
    echo "usage: $0 -i OSD_ID -d OSD_DISK -f FQDN -c CLUSTER_NAME" > /dev/stderr
    exit $USAGE
fi

ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *' &&
ceph-authtool --create-keyring /var/lib/ceph/admin/${CLUSTER_NAME}.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow' &&
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/admin/${CLUSTER_NAME}.keyring &&
monmaptool --create --add ${FQDN} ${MON_IP} --fsid ${FSID} /tmp/monmap &&
mkdir -p /var/lib/ceph/mon/${CLUSTER_NAME}-${FQDN} &&
ceph-mon --cluster ${CLUSTER_NAME} --mkfs -i ${FQDN} --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring &&
touch /var/lib/ceph/mon/${CLUSTER_NAME}-${FQDN}/done &&
rm -v /tmp/ceph.mon.keyring &&
exit 0
exit 1
