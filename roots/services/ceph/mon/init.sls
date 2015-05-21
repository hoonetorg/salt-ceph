include:
  - services.ceph.base.pkgs

{% set fsid = pillar.ceph.cluster.uuid %}

create-ceph-cluster:
  cmd.script:
    - name: salt://templates/ceph/create_cluster.sh
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

ceph:
  service.running:
    - enable: True
    - require:
      - cmd: create-ceph-cluster
      - cmd: create-ceph-restapi-keyring

start-ceph-mon:
  cmd.run:
    - name: ceph-mon -i {{ grains.fqdn }}
    - require:
      - cmd: create-ceph-cluster
    - unless: ps -e | awk '{ print $4 }' | grep '^ceph-mon$'

restart-ceph-mon:
  cmd.wait:
    - name: pkill ceph-mon; ceph-mon -i {{ grains.fqdn }}
    - require:
      - cmd: create-ceph-cluster
      - cmd: create-ceph-restapi-keyring
