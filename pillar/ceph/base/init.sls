base:
  repos:
    ceph:
      name: deb http://debian.arkena.net/debian-ceph/current stable main
      key_url: salt://ceph/base/bucket/gpg/ceph.asc
  pkgs:
    base: [
    ]
  ceph:
    user:
      name: cephyu
      uid: 1467
