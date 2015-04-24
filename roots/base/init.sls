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
    - source: salt://base/bucket/ssh/{{ grains.id }}.pub

#
# cluster nameserver and domain
#

cluster resolvconf:
  file.blockreplace:
    - name: /etc/resolv.conf
    - marker_start: "### START ZONE {{ pillar.base.domain }}"
    - marker_end: "### END ZONE {{ pillar.base.domain }}"
    - prepend_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - content: ''

cluster zone {{ pillar.base.domain }}:
  file.accumulated:
    - filename: /etc/resolv.conf
    - name: zone {{ pillar.base.domain }}
    - require_in:
      - file: cluster resolvconf
    - text:
      - "domain {{ pillar.base.domain }}"
      - "search {{ pillar.base.domain }}"
      {% for nameserver in pillar.base.nameservers %}- "nameserver {{ nameserver }}"
      {% endfor %}
