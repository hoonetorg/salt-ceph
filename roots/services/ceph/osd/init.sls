include:
  - services.ceph.base.pkgs

{% for disk in pillar.ceph.osd.disks %}
ceph-osd-dir-disk-{{disk}}:
  file.directory:
    - name: /var/local/osd/{{ disk }}
    - makedirs: True
    - watch_in:
      - event: add_osd-{{grains.id}}-event
{% endfor %}

add_osd-{{grains.id}}-event:
  event.wait:
    - name: 'ceph/osd/add'
    - data:
        disklist: {{ pillar.ceph.osd.disks }}
