#
# ceph pkgs
#

ceph-pkgs:
  pkg.installed:
    - fromrepo: jessie
    - pkgs:
      - ceph
      - ceph-mds
      - ceph-common
      - ceph-fs-common
      - radosgw
      - gdisk
