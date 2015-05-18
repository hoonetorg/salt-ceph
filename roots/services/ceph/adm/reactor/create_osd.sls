{% set user_name = pillar.ceph.base.user.name %}
{% set user_home = '/home/' + pillar.ceph.base.user.name %}
{% set ceph_dir = user_home + '/' + pillar.ceph.adm.clusterdir %}
{% set osd_name = pillar.reactor.osd.name %}

ssh-fingerprint-{{osd_name}}:
  cmd.run:
    - name: ssh-keyscan -H {{ osd_name }} >> {{ user_home }}/.ssh/known_hosts
    - user: {{ user_name }}

zap-osd-{{osd_name}}:
  cmd.run:
    - name: ceph-deploy disk zap {% for disk in pillar.reactor.osd.disklist
      %}{{ osd_name }}:{{ disk }} {% endfor %}
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}

prepare-osd-{{osd_name}}:
  cmd.wait:
    - name: ceph-deploy osd prepare {% for disk in pillar.reactor.osd.disklist
      %}{{ osd_name }}:{{ disk }} {% endfor %} --fs-type=ext4
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}
    - watch:
      - cmd: zap-osd-{{osd_name}}
