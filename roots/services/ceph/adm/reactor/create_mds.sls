{% set user_name = pillar.ceph.base.user.name %}
{% set user_home = '/home/' + pillar.ceph.base.user.name %}
{% set ceph_dir = user_home + '/' + pillar.ceph.adm.clusterdir %}
{% set mds_name = pillar.reactor.mds.name %}

ssh-fingerprint-{{mds_name}}:
  cmd.run:
    - name: ssh-keyscan -H {{ mds_name }} >> {{ user_home }}/.ssh/known_hosts
    - user: {{ user_name }}

create-mds-{{mds_name}}:
  cmd.run:
    - name: ceph-deploy mds create {{ mds_name }}
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}
