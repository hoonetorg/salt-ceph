{% set cluster_name = pillar.ceph.cluster.name %}
{% set mon_id, mon_fqdn = salt['mine.get']('ceph-mon-*', 'fqdn').items()[0] %}

{% set keyring_dir = '/var/lib/ceph/restapi' %} # warning:
# modifying this will require a modification in the bootstrap module as well
{% set keyring_file = keyring_dir ~ '/' ~ cluster_name ~ '.keyring' %}
{% set cephrestapi_wsgi = '/var/www/inkscope/inkscopeCtrl/ceph-rest-api.wsgi' %}

## mongodb

mongodb:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: mongodb

mongodb-bind-ip:
  file.replace:
    - name: /etc/mongodb.conf
    - pattern: "^bind_ip[ ]=[ ]127.0.0.1$"
    - repl: 'bind_ip = 0.0.0.0'
    - append_if_not_found: True
    - watch_in:
      - service: mongodb

mongodb-user-db:
  mongodb_user.present:
    - user: admin
    - name: {{ pillar.inkscope.base.mongo.user }}
    - passwd: {{ pillar.inkscope.base.mongo.pass }}
    - database: {{ pillar.inkscope.base.mongo.user }}

## apache stuff
{% set api_url = "http://localhost:" ~ pillar.inkscope.adm.api.port
~ "/ceph_rest_api/api/v0.1" %}
{% set vhost = pillar.inkscope.adm.vhost.name %}
{% set port = pillar.inkscope.adm.api.port %}

apache2:
  pkg.installed:
    - require_in:
      - service: apache2
  service:
    - running

restart-apache:
  cmd.wait:
    - name: service apache2 restart
    - order: last
    - watch:
      - service: apache2

apache-mod_wsgi:
  pkg.installed:
    - name: libapache2-mod-wsgi
    - watch_in:
      - service: apache2

apache-proxy_http-mod:
  apache_module.enable:
    - name: proxy_http
    - watch_in:
      - service: apache2

apache-rewrite-mod:
  apache_module.enable:
    - name: proxy_http
    - watch_in:
      - service: apache2

apache-inkscope-port:
  file.append:
    - name: /etc/apache2/ports.conf
    - text:
      - "Listen {{ port }}"
    - watch_in:
      - service: apache2
      - cmd: restart-apache # otherwise ports won't get open

apache-inkscope-vhost:
  file.managed:
    - name: /etc/apache2/sites-available/{{ vhost }}.conf
    - source: salt://templates/inkscope/adm/inkscope_vhost.conf
    - template: jinja
    - context:
        port: {{ port }}
        servername: localhost
        serveralias:
          - {{ grains.host }}
          - {{ grains.fqdn }}
        proxypassrule: /ceph-rest-api {{ api_url }}

apache-enable-inkscope-vhost:
  cmd.wait:
    - name: a2ensite {{ vhost }}
    - watch:
      - file: apache-inkscope-vhost
    - watch_in:
      - service: apache2

# ceph api keyring/conf

ceph-api-keyring-dir:
  file.directory:
    - name: {{ keyring_dir }}
    # if this fails it probably means ceph packages are missing or corrupt
    - makedirs: False

ceph-cluster-restapi-keyring:
  file.managed:
    - name: {{ keyring_file }}
    - user: root
    - group: root
    - mode: 440
    - require:
      - file: ceph-api-keyring-dir
    - source: salt://templates/ceph/tmpl.keyring
    - template: jinja
    - context:
      nodetype: restapi
      # this requires a mine.update on the monitor
      key: {{ salt['mine.get'](mon_id, 'bootstrap.api')[mon_id] }}

ceph-rest-api-clusterconf:
  file.blockreplace:
    - name: /etc/ceph/{{ cluster_name }}.conf
    - marker_start: "## DO NOT EDIT -- begin ceph-rest-api"
    - marker_end: "## DO NOT EDIT -- end ceph-rest-api"
    - content: '[client.restapi]'
    - append_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - require:
      - file: ceph-cluster-restapi-keyring
      - file: ceph-conf-global-section
    - watch_in:
      - service: apache2

ceph-rest-api-clusterconf-accumulated:
  file.accumulated:
    - filename: /etc/ceph/{{ cluster_name }}.conf
    - text:
      - "log_file = /dev/null"
      - "keyring = {{ keyring_file }}"
    - require_in:
      - file: ceph-rest-api-clusterconf

ceph-restapi-keyring-read-rights:
  cmd.run:
    - name: setfacl -m u:www-data:r {{ keyring_file }}
    - unless: getfacl {{ keyring_file }} | grep "user:www-data:r"

## inkscope

cephprobe-unit-file:
  file.managed:
    - name: /etc/systemd/system/cephprobe.service
    - source: salt://templates/inkscope/adm/cephprobe.service

inkscope-cephprobe:
  service.running:
    - name: cephprobe
    - enable: True
    - require:
      - service: mongodb
      - mongodb_user: mongodb-user-db
    - watch:
      - file: inkscope-opt-conf

patch-cephrestapi-wsgi-config:
  cmd.run:
    - name: sed -i 's|\("ceph_conf", "/etc/ceph/\)[^\.]*.conf"|\1{{
      cluster_name }}.conf"|g' {{ cephrestapi_wsgi }}
    - unless: egrep -q '"ceph_conf", "/etc/ceph/{{ cluster_name }}.conf"' {{
      cephrestapi_wsgi }}
    - watch_in:
      - service: apache2

patch-cephrestapi-wsgi-cluster-name:
  cmd.run:
    - name: sed -i 's|^ceph_cluster_name[ \t]*=.*|ceph_cluster_name="{{
      cluster_name }}"|g' {{ cephrestapi_wsgi }}
    - unless: egrep -q '^ceph_cluster_name="{{ cluster_name }}"$' {{
      cephrestapi_wsgi }}
    - watch_in:
      - service: apache2
