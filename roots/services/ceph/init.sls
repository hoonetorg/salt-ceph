include:
  - services.ceph.base
  {% for type in salt['pillar.get']("ceph:node:type", []) %}
  - services.ceph.{{ type }}
  {% endfor %}
