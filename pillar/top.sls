base:
  '*':
    - ceph.base
    - ceph.base.nodes
  'ceph-adm-*':
    - ceph.adm
    - ceph.cluster.nodes
    - ceph.cluster.config
  'ceph-mds-*':
    - ceph.mds
  'ceph-mon-*':
    - ceph.monitor
  'ceph-osd-*':
    - ceph.osd
