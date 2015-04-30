#
# ports opening with ferm
#

ferm ceph-mon rules:
  file.append:
    - name: /etc/ferm/ferm.conf
    - source: salt://ceph/base/templates/ferm.conf
    - template: jinja
    - context:
        open_ports: {{ pillar.base.ferm.open_ports }}


ferm reload:
  cmd.wait:
    - name: ferm /etc/ferm/ferm.conf
    - watch:
      - file: ferm ceph-mon rules
