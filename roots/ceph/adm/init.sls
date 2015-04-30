#
# ceph needs passwordless auth to a user with passwordless sudo rights
# on every single node
#

{% set user_name = pillar.base.ceph.user.name %}
{% set user_home = '/home/' + pillar.base.ceph.user.name %}
{% set ceph_dir = user_home + '/' + pillar.adm.clusterdir %}

ceph adm identity:
  file.managed:
    - name: {{ user_home }}/.ssh/id_rsa
    - user: {{ user_name }}
    - group: {{ user_name }}
    - mode: 600
    - source: salt://ceph/base/bucket/ssh/{{ grains.id }}

ceph adm pubkey:
  file.managed:
    - name: /home/{{ pillar.base.ceph.user.name }}/.ssh/id_rsa.pub
    - user: {{ user_name }}
    - group: {{ user_name }}
    - mode: 600
    - source: salt://ceph/base/bucket/ssh/{{ grains.id }}.pub

{% for node in pillar.cluster.nodes.initial %}
node {{ node }} ssh fingerprint:
  cmd.run:
    - name: ssh-keyscan -H {{ node }} >> {{ user_home }}/.ssh/known_hosts
    - user: {{ user_name }}
    - unless: test -n "`ssh-keygen -q -H -F {{ node }} `"

{% set shortname = node.split('.')[0] %}
shortname {{ shortname }} ssh fingerprint:
  cmd.run:
    - name: ssh-keyscan -H {{ shortname }} >> {{ user_home }}/.ssh/known_hosts
    - user: {{ user_name }}
    - unless: test -n "`ssh-keygen -q -H -F {{ shortname }} `"
{% endfor %}

ceph cluster dir:
  file.directory:
    - name: {{ ceph_dir }}
    - user: {{ user_name }}
    - group: {{ user_name }}
    - mode: 750

create ceph cluster:
  cmd.run:
    - name: ceph-deploy new {% for node in pillar.cluster.nodes.initial %} {{
      node }}{% endfor %}
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}
    - unless: test -f {{ ceph_dir }}/ceph.mon.keyring
    - watch_in:
      - cmd: ceph deploy nodes
      - cmd: ceph create monitors

set cluster size:
  file.append:
    - name: {{ ceph_dir }}/ceph.conf
    - text:
      - "osd pool default size = {{ pillar.cluster.size }}"

ceph deploy nodes:
  cmd.wait:
    - name: ceph-deploy install --no-adjust-repos {{ grains.localhost }}{%
      for node in pillar.cluster.nodes.initial %} {{ node }}{% endfor %}
    - user: {{ user_home }}
    - cwd: {{ ceph_dir }}

ceph create monitors:
  cmd.wait:
    - name: ceph-deploy mon create-initial
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}

ceph create admin node:
  cmd.wait:
    - name: ceph-deploy admin {{ grains.localhost }}{%
      for node in pillar.cluster.nodes.initial %} {{ node }}{% endfor %}
    - user: {{ user_name }}
    - cwd: {{ ceph_dir }}
