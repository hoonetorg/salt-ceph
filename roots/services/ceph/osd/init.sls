include:
  - services.ceph.base.pkgs

{% for disk in pillar.ceph.osd.disks %}
create-ceph-osd-{{disk}}:
  cmd.script:
    - name: salt://templates/ceph/create_osd.sh
    - unless: egrep "^fsid[ ]*=" /etc/ceph/ceph.conf
    - creates: /var/lib/ceph/mon/{{ grains.fqdn }}/done
    - require:
      - pkg: ceph-pkgs
    - template: jinja
    - context:
      fsid: {{ fsid }}
      fqdn: {{ grains.fqdn }}
      ip: {{ grains.fqdn_ip4[1] }}
      nodes: {{ pillar.ceph.cluster.nodes.initial }}
      pool_size: {{ pillar.ceph.cluster.pool_size }}
      cluster_name: {{ pillar.ceph.cluster.name }}
{% endfor %}

add_osd-{{grains.id}}-event:
  event.wait:
    - name: 'ceph/osd/add'
    - data:
        disklist: {{ pillar.ceph.osd.disks }}
