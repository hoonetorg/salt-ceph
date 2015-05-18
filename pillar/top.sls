base:
  '*':
    - roles.ceph
    - roles.inkscope
  'ceph-adm-1':
    - roles.ceph.cluster.config
    - roles.ceph.cluster.nodes
    - roles.ceph.adm
    - roles.inkscope.adm
  '* and not ceph-adm-*':
    - match: compound
    - roles.ceph.base.nodes
    - roles.inkscope.node
  'ceph-mon-1':
    - roles.inkscope.mon # only one cephrestapi needed
  'ceph-mon-*':
    - roles.ceph.mon
  'ceph-osd-*':
    - roles.ceph.osd
  'ceph-mds-*':
    - roles.ceph.mds
