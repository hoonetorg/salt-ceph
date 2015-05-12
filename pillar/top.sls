base:
  '*':
    - ceph.base
    - ceph.base.nodes
    - inkscope.base
  '* and not ceph-adm-*':
    - match: compound
    - inkscope.base.sysprobe
  'ceph-adm-*':
    - ceph.adm
    - ceph.cluster.nodes
    - ceph.cluster.config
    - inkscope.admviz
  'ceph-mds-*':
    - ceph.mds
  'ceph-mon-*':
    - ceph.monitor
  'ceph-mon-1*':
    - inkscope.monitor
  'ceph-osd-*':
    - ceph.osd
