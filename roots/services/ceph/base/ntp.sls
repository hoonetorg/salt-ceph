/etc/systemd/timesyncd.conf:
  file.managed:
    - source: salt://templates/ceph/timesyncd.conf
    - template: jinja
    - makedirs: True
    - context:
        servers: {{ pillar.ceph.base.ntp.servers }}
    - watch_in:
      - service: systemd-timesyncd

systemd-timesyncd:
  service.running:
    - enable: True
