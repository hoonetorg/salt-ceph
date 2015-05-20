base:
  '*':
    {% for k, v in pillar.get('services', {}).iteritems() %}
    {% if v %}
    - services.{{ k }}
    {% endif %}
    {% endfor %}
