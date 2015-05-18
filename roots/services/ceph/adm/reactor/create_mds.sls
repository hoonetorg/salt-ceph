ssh-fingerprint-{{pillar.reactor.mds.name}}:
  cmd.run:
    - name: ssh-keyscan -H {{ pillar.reactor.mds.name }} >> /home/{{
      pillar.ceph.base.user.name }}/.ssh/known_hosts
    - user: {{ pillar.ceph.base.user.name }}

create-mds-{{pillar.reactor.mds.name}}:
  cmd.run:
    - name: ceph-deploy mds create {{ pillar.reactor.mds.name }}
    - user: {{ pillar.ceph.base.user.name }}
    - cwd: /home/{{ pillar.ceph.base.user.name }}/{{ pillar.ceph.adm.clusterdir }}/
