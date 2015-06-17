include:
  - services.ceph.base.pkgs

kek:
  file.append:
    - name: /etc/systemd/system/bart\x2d2.service
    - text: |
        [Service]
        Type=oneshot
        ExecStart=/bin/echo bite

asd:
  service.running:
    - name: bart\x2d2
    - require:
      - file: kek

qweqw:
  file.append:
    - name: /etc/systemd/system/pute.service
    - text: |
        [Service]
        Type=oneshot
        ExecStart=/bin/echo bite

kak:
  service.running:
    - name: pute
    - require:
      - file: qweqw
