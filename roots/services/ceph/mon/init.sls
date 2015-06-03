include:
  - services.ceph.base.pkgs

{% set fsid = pillar.ceph.cluster.uuid %}
{% set fqdn = grains.fqdn %}
{% set cluster_name = pillar.ceph.cluster.name %}

/var/lib/ceph/admin:
  file:
    - directory

# ceph config file
ceph-conf-global-section-accumulator-mon:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "osd journal size = 1024"
      - "osd pool default size = {{ pillar.ceph.cluster.pool_size }}"
    - require_in:
      - file: ceph-conf-global-section

ceph-conf-admin-section:
  file.blockreplace:
    - name: /etc/ceph/{{ cluster_name }}.conf
    - marker_start: "## DO NOT EDIT -- begin {{ cluster_name }} admin"
    - marker_end: "## DO NOT EDIT -- end {{ cluster_name }} admin"
    - content: '[client.admin]'
    - append_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - require:
      - file: ceph-cluster-conf
    - watch_in:
      - service: ceph-mon@{{ fqdn }}

ceph-conf-admin-section-accumulator:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "keyring = /var/lib/ceph/admin/{{ cluster_name }}.keyring"
    - require_in:
      - file: ceph-conf-admin-section

ceph-conf-mon-section:
  file.blockreplace:
    - name: /etc/ceph/{{ cluster_name }}.conf
    - marker_start: "## DO NOT EDIT -- begin {{ cluster_name }} mon"
    - marker_end: "## DO NOT EDIT -- end {{ cluster_name }} mon"
    - content: '[mon]'
    - append_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - require:
      - file: ceph-cluster-conf
    - watch_in:
      - service: ceph-mon@{{ fqdn }}
      - service: sysprobe

ceph-conf-mon-section-accumulator:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "mon data = /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }}"
    - require_in:
      - file: ceph-conf-mon-section

ceph-conf-mon.{{fqdn}}-section:
  file.blockreplace:
    - name: /etc/ceph/{{ cluster_name }}.conf
    - marker_start: "## DO NOT EDIT -- begin {{ cluster_name }} id mon.{{ fqdn }}"
    - marker_end: "## DO NOT EDIT -- end {{ cluster_name }} id mon.{{ fqdn }}"
    - content: '[mon.{{ fqdn }}]'
    - append_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - require:
      - file: ceph-cluster-conf
    - watch_in:
      - service: ceph-mon@{{ fqdn }}
      - service: sysprobe

ceph-conf-mon.{{fqdn}}-section-accumulator:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "host = {{ fqdn }}"
      - "mon addr = {{ grains.ip4_interfaces[pillar.ceph.base.ifaces.pub][0] }}:6789"
    - require_in:
      - file: ceph-conf-mon.{{fqdn}}-section

ceph-mon-unit-file:
  file.managed:
    - name: /etc/systemd/system/ceph-mon@.service
    - source: salt://templates/ceph/ceph-mon@.service
    - template: jinja
    - context:
      cluster_name: {{ cluster_name }}

ceph-mon@{{fqdn}}:
  service.running:
    - enable: True
    - require:
      - file: ceph-mon-unit-file
      - file: ceph-cluster-conf
      - file: ceph-conf-global-section
      - file: ceph-conf-mon-section
