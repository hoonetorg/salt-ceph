#ceph-cluster-bootstrap-osd-keyring:
  #file.managed:
    #- name: /var/lib/ceph/bootstrap-osd/{{ pillar.ceph.cluster.name }}.keyring
    #- user: root
    #- group: root
    #- mode: 440
    #- source: salt://templates/ceph/tmpl.keyring
    #- template: jinja
    #- context:
      #nodetype: bootstrap-osd
      ## this requires a mine.update on the monitor
      #key: { salt['mine.get'](mon_id, 'bootstrap.osd')[mon_id] }

ceph-osd-unit-file:
  file.managed:
    - name: /etc/systemd/system/ceph-osd@.service
    - source: salt://templates/ceph/ceph-osd@.service
    - template: jinja
    - context:
      cluster_name: {{ pillar.ceph.cluster.name }}
