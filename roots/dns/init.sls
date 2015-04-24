dnsmasq:
  pkg:
    - installed
  file.managed:
    - name: {{ pillar.dnsmasq.cfg_file }}
    - user: root
    - group: root
    - source: salt://dns/bucket/templates/dnsmasq.conf
    - template: jinja
    - context:
      iface: {{ pillar.dnsmasq.iface }}
      ipaddress: {{ grains.ip_interfaces[pillar.dnsmasq.iface][0] }}
      domain: {{ pillar.base.domain }}
  service.running:
    - enable: True
    - require:
      - pkg: dnsmasq
      - file: {{ pillar.dnsmasq.cfg_file }}
    - watch:
      - file: {{ pillar.dnsmasq.cfg_file }}

dns host list:
  file.append:
    - name: /etc/hosts
    - text:
      {% for name, ip in pillar.dnsmasq.hosts.items() %} - "{{ ip }} {{ name }}"
      {% endfor %}
