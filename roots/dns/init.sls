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

remove loopback alias 0:
  host.absent:
    - name: {{ grains.nodename }}
    - ip: 127.0.0.1

remove loopback alias 1:
  host.absent:
    - name: {{ grains.nodename }}
    - ip: 127.0.1.1

{% for name, ip in pillar.dnsmasq.hosts.items() %}
cluster node {{ name }}:
  host.present:
    - name: {{ name }}
    - ip: {{ ip }}
{% endfor %}
