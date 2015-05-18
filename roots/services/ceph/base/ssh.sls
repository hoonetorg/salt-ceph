ceph-sudoers-file:
  file.managed:
    - name: /etc/sudoers.d/{{ pillar.ceph.base.user.name }}
    - user: root
    - group: root
    - mode: 440

ceph-sudoers-entries:
  file.append:
    - name: /etc/sudoers.d/{{ pillar.ceph.base.user.name }}
    - text:
      - "{{ pillar.ceph.base.user.name }} {{ grains.host }}=(ALL) NOPASSWD: ALL"

ceph-user-ssh-authorized-keys-file:
  file.managed:
    - name: /home/{{ pillar.ceph.base.user.name }}/.ssh/authorized_keys
    - user: {{ pillar.ceph.base.user.name }}
    - group: {{ pillar.ceph.base.user.name }}
    - makedirs: True

ceph-ssh-authorized-key:
  file.append:
    - name: /home/{{ pillar.ceph.base.user.name }}/.ssh/authorized_keys
    - sources:
      {% for node in pillar.ceph.nodes.adm %}
      - salt://bucket/ceph/base/ssh/{{ node }}.pub
      {% endfor %}
