base:
  '*':
    - roles.inkscope
  'ceph-adm-1':
    - roles.inkscope.adm
  '* and not ceph-adm-*':
    - match: compound
    - roles.ceph
    - roles.ceph.base.nodes
    - roles.inkscope.node
  'ceph-mon-1':
    - roles.inkscope.mon # main monitor
    - roles.ceph.cluster.config
    - roles.ceph.cluster.nodes
  'ceph-mon-*':
    - roles.ceph.mon
  'ceph-osd-*':
    - roles.ceph.osd
  'ceph-mds-*':
    - roles.ceph.mds
