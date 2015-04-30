base:
  '*':
    - ceph.base
  'ceph-adm-*':
    - ceph.adm
  'ceph-mds-*':
    - ceph.base.ferm
    - ceph.mds
  'ceph-mon-*':
    - ceph.base.ferm
    - ceph.monitor
  'ceph-osd-*':
    - ceph.base.ferm
    - ceph.osd
