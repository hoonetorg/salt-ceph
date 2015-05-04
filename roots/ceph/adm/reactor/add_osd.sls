{% set user_name = pillar.base.ceph.user.name %}
{% set user_home = '/home/' + pillar.base.ceph.user.name %}
{% set ceph_dir = user_home + '/' + pillar.adm.clusterdir %}
{% set osd_name = pillar.osd.name %}

{{ osd_name }} ssh fingerprint:
  cmd.run:
    - name: ssh-keyscan -H {{ osd_name }} >> {{ user_home }}/.ssh/known_hosts
    - user: {{ user_name }}

install ceph on osd {{ osd_name }}:
  cmd.run:
    - name: ceph-deploy install --no-adjust-repos {{ osd_name }}
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}

zap osd {{ osd_name }}:
  cmd.run:
    - name: ceph-deploy disk zap {% for disk in pillar.osd.disklist
      %}{{ osd_name }}:{{ disk }} {% endfor %}
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}

prepare osd {{ osd_name }}:
  cmd.wait:
    - name: ceph-deploy osd prepare {% for disk in pillar.osd.disklist
      %}{{ osd_name }}:{{ disk }} {% endfor %} --fs-type=ext4
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}
    - watch:
      - cmd: zap osd {{ osd_name }}
