include:
  - services.ceph.base.pkgs

{% set fsid = pillar.ceph.cluster.uuid %}
{% set fqdn = grains.fqdn %}
{% set cluster_name = pillar.ceph.cluster.name %}

ceph-conf-global-section-accumulator-mon:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "osd journal size = 1024"
      - "osd pool default size = {{ pillar.ceph.cluster.pool_size }}"
    - require_in:
      - file: ceph-conf-global-section

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
    - require_in:
      - cmd: create-ceph-cluster
    - watch_in:
      - service: ceph-mon
      - service: sysprobe

ceph-conf-mon-section-accumulator:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "mon data = /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }}"
    - require_in:
      - file: ceph-conf-mon-section

create-ceph-cluster:
  cmd.script:
    - name: salt://templates/ceph/create_cluster.sh
    - watch_in:
      - service: ceph-mon
    - creates: /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }}/done
    - require:
      - pkg: ceph-pkgs
      - file: ceph-conf-global-section
    - template: jinja
    - context:
      fsid: {{ fsid }}
      fqdn: {{ fqdn }}
      ip: {{ grains.fqdn_ip4[1] }} # [0] == loopback
      cluster_name: {{ pillar.ceph.cluster.name }}

{% for nodetype in ['osd', 'mds'] %}
create-bootstrap-{{nodetype}}-keyring:
  cmd.script:
    - name: salt://templates/ceph/create_bootstrap_keyring.sh
    - require:
      - service: ceph-mon
    - unless: ceph -c /etc/ceph/{{ cluster_name }}.conf auth get client.bootstrap-{{ nodetype }}
    - template: jinja
    - context:
      cluster_name: {{ cluster_name }}
      nodetype: {{ nodetype }}
{% endfor %}

ceph-mon-unit-env-file:
  file.managed:
    - name: /etc/ceph/envfile
    - contents: |
        FQDN={{ fqdn }}
        CONF=/etc/ceph/{{ cluster_name }}.conf

ceph-mon-unit-file:
  file.managed:
    - name: /etc/systemd/system/ceph-mon.service
    - source: salt://templates/ceph/ceph-mon.service
    - require:
      - file: ceph-mon-unit-env-file

ceph-mon:
  service.running:
    - enable: True
    - require:
      - file: ceph-mon-unit-file
      - file: ceph-cluster-conf
      - file: ceph-conf-global-section
      - file: ceph-conf-mon-section

restart-ceph-mon: # ugly, but needed to avoid recursive requisites
  cmd.wait:
    - name: service ceph-mon restart
