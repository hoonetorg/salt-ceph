include:
  - services.ceph.base.pkgs

{% set fsid = salt['cmd.run']('uuidgen') %}

create-ceph-cluster:
  cmd.script:
    - name: salt://templates/ceph/create_cluster.sh
    - unless: egrep "^fsid[ ]*=" /etc/ceph/ceph.conf
    - creates: /var/lib/ceph/mon/{{ grains.fqdn }}/done
    - template: jinja
    - context:
      fsid: {{ fsid }}
      fqdn: {{ grains.fqdn }}
      ip: {{ grains.fqdn_ip4[1] }}
      nodes: {{ pillar.ceph.cluster.nodes.initial }}
      pool_size: {{ pillar.ceph.cluster.pool_size }}
      cluster_name: {{ pillar.ceph.cluster.name }}

ceph:
  service.running:
    - require:
      - cmd: create-ceph-cluster
    - enable: True

start-ceph-mon:
  cmd.wait:
    - name: service ceph start mon.{{ grains.fqdn }}
    - watch:
      - cmd: create-ceph-cluster
