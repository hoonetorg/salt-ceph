base:
  repos:
    ceph:
      name: deb http://debian.arkena.net/debian-ceph/hammer wheezy main
      key_url: salt://base/bucket/gpg/ceph.asc
  pkgs:
    base: [
      'tmux',
    ]
  ceph:
    user:
      name: cephyu
      uid: 1467
