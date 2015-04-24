#
# ceph needs passwordless auth to a user with passwordless sudo rights
# on every single node
#

ceph adm identity:
  file.managed:
    - name: /home/{{ pillar.base.ceph.user.name }}/.ssh/{{ grains.id }}
    - user: {{ pillar.base.ceph.user.name }}
    - group: {{ pillar.base.ceph.user.name }}
    - mode: 600
    - source: salt://ssh/{{ grains.id }}

ceph cluster dir:
  file.directory:
    - name: /home/{{ pillar.base.ceph.user.name }}/{{ pillar.adm.clusterdir }}
    - user: {{ pillar.base.ceph.user.name }}
    - group: {{ pillar.base.ceph.user.name }}
    - mode: 750

create ceph cluster:
  cmd.wait:
    - name: 
    - watch:
      - file: ceph cluster dir
