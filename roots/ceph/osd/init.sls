{% for disk, path in pillar.osd.disks.items() %}
ceph osd dir disk_{{ disk }}:
  file.directory:
    - name: {{ path }}
    - watch_in:
      - event: add_osd disk_{{ disk }} event

add_osd disk_{{ disk }} event:
  event.wait:
    - name: 'ceph/osd/add'
    - data:
        path: {{ path }}
{% endfor %}
