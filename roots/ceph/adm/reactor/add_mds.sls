{{ pillar.mds.name }} ssh fingerprint:
  cmd.run:
    - name: ssh-keyscan -H {{ pillar.mds.name }} >> /home/{{
      pillar.base.ceph.user.name }}/.ssh/known_hosts
    - user: {{ pillar.base.ceph.user.name }}

install ceph on mds {{ pillar.mds.name }}:
  cmd.run:
    - name: ceph-deploy install --no-adjust-repos {{ pillar.mds.name }}
    - user: {{ pillar.base.ceph.user.name }}
    - cwd: /home/{{ pillar.base.ceph.user.name }}/{{ pillar.adm.clusterdir }}/

create mds {{ pillar.mds.name }}:
  cmd.run:
    - name: ceph-deploy mds create {{ pillar.mds.name }}
    - user: {{ pillar.base.ceph.user.name }}
    - cwd: /home/{{ pillar.base.ceph.user.name }}/{{ pillar.adm.clusterdir }}/
