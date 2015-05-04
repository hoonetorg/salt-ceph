base:
  repos:
    ceph:
      name: deb http://debian.arkena.net/debian-smartjog/ stable smartjog
      #key_url: salt://ceph/base/bucket/gpg/ceph.asc
      file: /etc/apt/sources.list.d/ceph.list
    cephdeploy:
      name: deb http://debian.arkena.net/debian-ceph/current stable main
      key_url: salt://ceph/base/bucket/gpg/ceph.asc
      file: /etc/apt/sources.list.d/ceph.list
  pkgs:
    base: [
    ]
  ceph:
    user:
      name: cephyu
      uid: 1467
