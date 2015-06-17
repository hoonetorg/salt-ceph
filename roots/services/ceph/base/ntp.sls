/etc/systemd/timesyncd.conf:
  file.managed:
    - source: salt://templates/ceph/timesyncd.conf
    - context:
        servers: {{ pillar.ceph.base.ntp.servers }}

enable-timesyncd:
  cmd.run:
    - name: timedatectl set-ntp true
    - unless: 'timedatectl status | egrep -q "^[ \t]+NTP enabled: yes$"'
