include:
  - services.ceph.base.ssh

ceph:
  service:
    - running
    - enable: True
