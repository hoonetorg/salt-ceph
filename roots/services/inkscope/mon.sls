{% set cluster_name = pillar.ceph.cluster.name %}
{% set keyring_cmd = "ceph -c /etc/ceph/" ~ cluster_name ~ ".conf " ~
"auth get-or-create client.restapi mds 'allow' osd 'allow *' mon 'allow *'" %}
{% set keyring_dir = '/var/lib/ceph/restapi' %} # warning:
# modifying this will require a modification in the bootstrap module as well
{% set keyring_file = keyring_dir ~ '/' ~ cluster_name ~ '.keyring' %}

## ceph-rest-api

ceph-api-keyring-dir:
  file.directory:
    - name: {{ keyring_dir }}
    # if this fails it probably means ceph packages are missing or corrupt
    - makedirs: False

create-ceph-restapi-keyring:
  cmd.run:
    - name: {{ keyring_cmd }} > {{ keyring_file }}
    - creates: {{ keyring_file }}
    - unless: ceph -c /etc/ceph/{{ cluster_name }}.conf auth get client.restapi
    - require:
      - file: ceph-api-keyring-dir
      - service: ceph-mon@{{ grains.fqdn }}

remove-ceph-restapi-keyring:
  file.absent:
    - name: {{ keyring_file }}
    - onfail:
      - cmd: create-ceph-restapi-keyring
