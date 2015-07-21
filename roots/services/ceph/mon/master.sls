{% set fsid = pillar.ceph.cluster.uuid %}
{% set fqdn = grains.fqdn %}
{% set cluster_name = pillar.ceph.cluster.name %}
{% set tmpdir = '/tmp/' ~ cluster_name ~ '-new-cluster' %}

create-ceph-cluster-{{cluster_name}}:
  cmd.script:
    - name: salt://templates/ceph/create_cluster.sh
    # ip: {{ grains.fqdn_ip4[1] }} because [0] == loopback
    - args: >
        -i {{ grains.fqdn_ip4[1] }}
        -d {{ fsid }}
        -f {{ fqdn }}
        -c {{ cluster_name }}
    - watch_in:
      - service: ceph-mon@{{ fqdn }}
    - creates: /var/lib/ceph/mon/{{ cluster_name }}-{{ fqdn }}/done
    - require:
      - pkg: ceph-pkgs
      - file: ceph-conf-global-section
      - file: ceph-conf-admin-section
      - file: ceph-conf-mon-section

remove-tmp-cluster-dir-onfail:
  file.absent:
    - name: {{ tmpdir }}
    - onfail:
      - service: ceph-mon@{{ fqdn }}

remove-tmp-cluster-dir:
  file.absent:
    - name: {{ tmpdir }}
    - require:
      - service: ceph-mon@{{ fqdn }}

{% for nodetype in ['osd', 'mds'] %}
create-bootstrap-{{nodetype}}-keyring:
  cmd.script:
    - name: salt://templates/ceph/create_bootstrap_keyring.sh
    - args: >
        -n {{ nodetype }}
        -c {{ cluster_name }}
    - require:
      - service: ceph-mon@{{ fqdn }}
    - unless: >
        ceph
        -c /etc/ceph/{{ cluster_name }}.conf
        auth get client.bootstrap-{{ nodetype }}

{% endfor %}
