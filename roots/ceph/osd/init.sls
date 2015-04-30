{% for disk, path in pillar.osd.disks.items() %}
ceph osd dir disk_{{ disk }}:
  file.directory:
    - name: {{ path }}
    - watch_in:
      - event: add_osd {{ grains.id }} event
{% endfor %}

add_osd {{ grains.id }} event:
  event.wait:
    - name: 'ceph/osd/add'
    - data:
        pathlist: [{% for disk, path in pillar.osd.disks.items()
          %}"{{ path }}", {% endfor %}]
