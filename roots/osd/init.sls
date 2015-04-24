#
# ports opening with ferm
#

ferm ceph-mon rules:
  file.append:
    - name: /etc/ferm/ferm.conf
    - source: salt://base/templates/ferm.conf
    - template: jinja
    - context:
      ports: {{ pillar.base.ferm.ports }}


#ferm reload:
#cmd.wait:
#- name: ferm /etc/ferm/ferm.conf
#- watch:
#- file: ferm ceph-mon rules
