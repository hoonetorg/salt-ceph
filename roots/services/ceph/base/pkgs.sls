{% set cluster_name = pillar.ceph.cluster.name %}
{% set public_network = salt['cmd.run'](
"ip a | grep " ~ grains.ip4_interfaces[pillar.ceph.base.ifaces.pub][0] ~
" | awk '{ print $2 }' | sed 's/\.[0-9]*\//.0\//'").rstrip()
%}

ceph-pkgs:
  pkg.installed:
    - fromrepo: jessie
    - pkgs:
      - uuid-runtime
      - hdparm
      - ceph
      - ceph
      - ceph-mds
      - ceph-common
      - ceph-fs-common
      - radosgw
      - gdisk

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
    - watch_in:
      {% if 'node' in pillar.ceph.node.type %}
      - service: sysprobe
      {% endif %}
      {% if 'mon' in pillar.ceph.node.type %}
      - service: ceph-mon@{{ grains.fqdn }}
      {% endif %}
      {% if 'adm' in pillar.ceph.node.type %}
      - service: inkscope-cephprobe
      {% endif %}

ceph-conf-global-section-accumulator-node:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "fsid = {{ pillar.ceph.cluster.uuid }}"
      - "mon initial members = {%
          for host, mon_fqdn in salt['mine.get']('ceph-mon-*', 'fqdn').items()
          %}{{ mon_fqdn }},{% endfor %}"
      - "mon host = {%
          for host, mon_ip in salt['mine.get']('ceph-mon-*', 'ipaddrs').items()
          %}{{ mon_ip[pillar.ceph.base.ifaces.pub][0] }},{% endfor %}"
      - "public network = {{ public_network }}"
      - "auth cluster required = cephx"
      - "auth service required = cephx"
      - "auth client required = cephx"
      - "filestore xattr use omap = true"
    - require_in:
      - file: ceph-conf-global-section

ceph-conf-symlink:
  file.symlink:
    - name: /etc/ceph/ceph.conf
    - target: /etc/ceph/{{ cluster_name }}.conf

ceph-var-lib-permissions:
  file.directory:
    - name: /var/lib/ceph
    - user: root
    - group: root
    - dir_mode: 555
    - file_mode: 440
    - recurse:
      - user
      - group
      - mode
    - order: last
