ceph-osd-unit-file:
  file.managed:
    - name: /etc/systemd/system/ceph-osd@.service
    - source: salt://templates/ceph/ceph-osd@.service
    - template: jinja
    - context:
      cluster_name: {{ pillar.ceph.cluster.name }}
