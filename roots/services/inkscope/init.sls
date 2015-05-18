include:
  - services.inkscope.base
  {% for type in salt['pillar.get']("inkscope:node:type", []) %}
  - services.inkscope.{{ type }}
  {% endfor %}
