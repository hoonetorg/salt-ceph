{% for disk in pillar.osd.disks %}
ceph osd dir disk_{{ disk }}:
  file.directory:
    - name: /var/local/osd/{{ disk }}
    - makedirs: True
    - watch_in:
      - event: add_osd {{ grains.id }} event
{% endfor %}

add_osd {{ grains.id }} event:
  event.wait:
    - name: 'ceph/osd/add'
    - data:
        disklist: {{ pillar.osd.disks }}
