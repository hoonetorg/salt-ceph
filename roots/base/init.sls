#
# pkgs
#

ceph repo:
  pkgrepo.managed:
    - name: {{ pillar.base.repos.ceph.name }}
    - key_url: {{ pillar.base.repos.ceph.key_url }}

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
    - name: {{ pillar.ceph.user.name }}
    - uid: {{ pillar.ceph.user.uid }}
    - shell: /bin/bash
    - createhome: True
    - home: /home/{{ pillar.ceph.user.name }}

ceph sudoers file:
  file.append:
    - name: /etc/sudoers.d/{{ pillar.ceph.user.name }}
    - user: root
    - group: root
    - mode: 440
    - text:
      - "{{ pillar.ceph.user.name }} {{ grains.host }}=(ALL) NOPASSWD: ALL"

ceph ssh authorized key:
  file.append:
    - name: /home/{{ pillar.ceph.user.name }}/.ssh/authorized_keys
    - user: {{ pillar.ceph.user.name }}
    - group: {{ pillar.ceph.user.name }}
    - source: salt://ssh/{{ grains.id }}.pub

#
# cluster nameserver and domain
#

cluster resolvconf:
  file.append:
    - name: /etc/resolv.conf
    - text:
      - "domain {{ pillar.base.domain }}"
      - "search {{ pillar.base.domain }}"
      {% for nameserver in pillar.base.nameservers %}
      - "nameserver {{ nameserver }}"
      {% endfor %}
