include:
  - services.ceph.base.pkgs

{% set fsid = pillar.ceph.cluster.uuid %}
{% set fqdn = grains.fqdn %}
{% set cluster_name = pillar.ceph.cluster.name %}
{% set public_network = salt['cmd.run'](
"ip a | grep " ~ grains.fqdn_ip4[1] ~
" | awk '{ print $2 }' | sed 's/\.[0-9]*\//.0\//'").rstrip()
%}

ceph-cluster-conf:
  file.managed:
    - name: /etc/ceph/{{ cluster_name }}.conf
    - require:
      - pkg: ceph-pkgs

ceph-conf-global-section:
  file.blockreplace:
    - name: /etc/ceph/{{ cluster_name }}.conf
    - marker_start: "## DO NOT EDIT -- begin {{ cluster_name }} global"
    - marker_end: "## DO NOT EDIT -- end {{ cluster_name }} global"
    - content: '[global]'
    - append_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - require:
      - file: ceph-cluster-conf
    - require_in:
      - file: ceph-rest-api-clusterconf
      - cmd: create-ceph-cluster
    - watch_in:
      - service: ceph-mon
      - service: inkscope-cephprobe
      - service: sysprobe

ceph-conf-global-section-accumulator:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "fsid = {{ fsid }}"
      - "osd pool default size = {{ pillar.ceph.cluster.pool_size }}"
      - "mon initial members = {{ fqdn }}{%
          for mem in pillar.ceph.cluster.nodes.initial %}{%
            if mem != fqdn %}, {{ mem }}{%
            endif %}{%
          endfor %}"
      - "mon host = {{ grains.fqdn_ip4[1] }}"
      - "public network = {{ public_network }}"
      - "auth cluster required = cephx"
      - "auth service required = cephx"
      - "auth client required = cephx"
      - "osd journal size = 1024"
      - "filestore xattr use omap = true"
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
      - file: ceph-rest-api-clusterconf
      - cmd: create-ceph-cluster
    - watch_in:
      - service: ceph-mon
      - service: inkscope-cephprobe
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
    - template: jinja
    - context:
      fsid: {{ fsid }}
      fqdn: {{ fqdn }}
      ip: {{ grains.fqdn_ip4[1] }} # [0] == loopback
      cluster_name: {{ pillar.ceph.cluster.name }}

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
