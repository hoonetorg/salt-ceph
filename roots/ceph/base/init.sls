#
# pkgs
#

ceph repo:
  pkgrepo.managed:
    - name: {{ pillar.base.repos.ceph.name }}
    - file: {{ pillar.base.repos.ceph.file }}
{% if pillar.base.repos.ceph.key_url is defined %}
    - key_url: {{ pillar.base.repos.ceph.key_url }}
{% endif %}

ceph-deploy repo:
  pkgrepo.managed:
    - name: {{ pillar.base.repos.cephdeploy.name }}
    - file: {{ pillar.base.repos.cephdeploy.file }}
{% if pillar.base.repos.cephdeploy.key_url is defined %}
    - key_url: {{ pillar.base.repos.cephdeploy.key_url }}
{% endif %}

{% for listname, pkglist in pillar.base.pkgs.items() %}
  {% for pkg in pkglist %}
{{ listname }} pkg {{ pkg }}:
  pkg.installed:
    - name: {{ pkg }}
  {% endfor %}
{% endfor %}

#
# ceph base user
#

ceph user:
  user.present:
    - name: {{ pillar.base.ceph.user.name }}
    - uid: {{ pillar.base.ceph.user.uid }}
    - shell: /bin/bash
    - createhome: True
    - home: /home/{{ pillar.base.ceph.user.name }}

ceph sudoers file:
  file.managed:
    - name: /etc/sudoers.d/{{ pillar.base.ceph.user.name }}
    - user: root
    - group: root
    - mode: 440

ceph sudoers entries:
  file.append:
    - name: /etc/sudoers.d/{{ pillar.base.ceph.user.name }}
    - text:
      - "{{ pillar.base.ceph.user.name }} {{ grains.host }}=(ALL) NOPASSWD: ALL"

ceph user ssh authorized keys file:
  file.managed:
    - name: /home/{{ pillar.base.ceph.user.name }}/.ssh/authorized_keys
    - user: {{ pillar.base.ceph.user.name }}
    - group: {{ pillar.base.ceph.user.name }}
    - makedirs: True

ceph ssh authorized key:
  file.append:
    - name: /home/{{ pillar.base.ceph.user.name }}/.ssh/authorized_keys
    - sources:
      {% for node in pillar.nodes.adm %}
      - salt://ceph/base/bucket/ssh/{{ node }}.pub
      {% endfor %}
