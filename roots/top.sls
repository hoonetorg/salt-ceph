base:
  '*':
    - base
  'ceph-adm-*':
    - adm
  'ceph-mon-*':
    - base.ferm
    - monitor
  'ceph-osd-*':
    - base.ferm
    - osd
