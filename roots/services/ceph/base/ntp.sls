ntp:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - watch:
      - file: /etc/ntp.conf

/etc/ntp.conf:
  file.managed:
    - contents: | {% for server in pillar.ceph.base.ntp.servers %}
        server {{ server }} iburst{% endfor %}
