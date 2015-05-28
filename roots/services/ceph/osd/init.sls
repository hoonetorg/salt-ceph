include:
  - services.ceph.base.pkgs

{% set mon_id, mon_fqdn = salt['mine.get']('ceph-mon-*', 'fqdn').items()[0] %}

ceph-cluster-bootstrap-osd-keyring:
  file.managed:
    - name: /var/lib/ceph/bootstrap-osd/{{ pillar.ceph.cluster.name }}.keyring
    - user: root
    - group: root
    - mode: 440
    - source: salt://templates/ceph/tmpl.keyring
    - template: jinja
    - context:
      nodetype: bootstrap-osd
      # this requires a mine.update on the monitor
      key: {{ salt['mine.get'](mon_id, 'bootstrap.osd')[mon_id] }}

{% for disk in pillar.ceph.osd.disks %}
create-ceph-osd-{{disk}}:
  cmd.script:
    - name: salt://templates/ceph/create_osd.sh
    # only if disk is not partitioned
    - unless: sed '1,/{{ disk }}/d' /proc/partitions | grep -q {{ disk }}
    - require:
      - pkg: ceph-pkgs
      - file: ceph-cluster-bootstrap-osd-keyring
    - template: jinja
    - context:
      fsid: {{ pillar.ceph.cluster.uuid }}
      disk: /dev/{{ disk }}
      cluster_name: {{ pillar.ceph.cluster.name }}
      bootstrap_key: /var/lib/ceph/bootstrap-osd/{{
        pillar.ceph.cluster.name }}.keyring
{% endfor %}

#add_osd-{{grains.id}}-event:
  #event.wait:
    #- name: 'ceph/osd/add'
    #- data:
        #disklist: {{ pillar.ceph.osd.disks }}
