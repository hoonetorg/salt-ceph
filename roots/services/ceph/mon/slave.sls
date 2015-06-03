{% set mon_id, mon_fqdn = salt['mine.get'](
pillar.ceph.nodes.mon.master, 'fqdn').items()[0] %}
{% set fqdn = grains.fqdn %}
{% set cluster_name = pillar.ceph.cluster.name %}
{% set tmpdir = '/tmp/' ~ cluster_name ~ '-new-mon' %}

ceph-admin-keyring:
  file.managed:
    - name: /var/lib/ceph/admin/{{ pillar.ceph.cluster.name }}.keyring
    - user: root
    - group: root
    - mode: 440
    - source: salt://templates/ceph/tmpl.keyring
    - template: jinja
    - context:
      nodetype: admin
      # this requires a mine.update on the monitor
      key: {{ salt['mine.get'](mon_id, 'bootstrap.admin')[mon_id] }}

remove-{{cluster_name}}-tmp-mon-dir-onfail:
  file.absent:
    - name: {{ tmpdir }}
    - onfail:
      - cmd: add-ceph-mon-{{cluster_name}}

create-ceph-mon-{{cluster_name}}:
  cmd.script:
    - name: salt://templates/ceph/create_mon.sh
    - require:
      - pkg: ceph-pkgs
      - file: ceph-conf-global-section
      - file: ceph-conf-admin-section
      - file: ceph-conf-mon-section
      - file: ceph-admin-keyring
    - require_in:
      - service: ceph-mon@{{ fqdn }}
    - unless: "test -d /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }} &&
      ceph -c /etc/ceph/{{ cluster_name }}.conf mon stat | grep -q '{{ fqdn }}'"
    - template: jinja
    - context:
      mon_id: {{ fqdn }}
      tmpdir: {{ tmpdir }}
      cluster_name: {{ cluster_name }}

add-ceph-mon-{{cluster_name}}:
  cmd.wait:
    - name: ceph -c /etc/ceph/{{ cluster_name }}.conf mon add {{ fqdn }} {{
      grains.fqdn_ip4[1] }}
    - require:
      - service: ceph-mon@{{ fqdn }}
    - watch:
      - cmd: create-ceph-mon-{{cluster_name}}

remove-{{cluster_name}}-tmp-mon-dir:
  file.absent:
    - name: {{ tmpdir }}
    - require:
      - cmd: add-ceph-mon-{{cluster_name}}
