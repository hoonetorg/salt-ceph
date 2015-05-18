include:
  - services.ceph.base.ferm

ceph-user:
  user.present:
    - name: {{ pillar.ceph.base.user.name }}
    - uid: {{ pillar.ceph.base.user.uid }}
    - shell: /bin/bash
    - createhome: True
    - home: /home/{{ pillar.ceph.base.user.name }}
