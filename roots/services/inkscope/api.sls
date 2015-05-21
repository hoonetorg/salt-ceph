{% set vhost = pillar.inkscope.mon.api.vhost %}
{% set port = pillar.inkscope.mon.api.port %}
{% set keyring_cmd = "ceph auth get-or-create client.restapi mds 'allow' osd 'allow *' mon 'allow *'" %}
{% set keyring_file = '/etc/ceph/ceph.client.restapi.keyring' %}
{% set pip_pkgs = pillar.inkscope.mon.pip_pkgs %}
{% set cephprobe_cfg = '/opt/inkscope/etc/cephprobe.conf' %}
{% set cephprobe_bin = '/opt/inkscope/bin/cephprobe.py' %}


## ceph-rest-api

create-ceph-restapi-keyring:
  cmd.run:
    - name: {{ keyring_cmd }} > {{ keyring_file }}
    - creates: {{ keyring_file }}
    - require:
      - cmd: start-ceph-mon
    - watch_in:
      - cmd: restart-ceph-mon

remove-ceph-restapi-keyring:
  file.absent:
    - name: {{ keyring_file }}
    - onfail:
      - cmd: create-ceph-restapi-keyring

ceph-rest-api-clusterconf:
  file.blockreplace:
    - name: /etc/ceph/ceph.conf
    - marker_start: "## DO NOT EDIT -- begin ceph-rest-api"
    - marker_end: "## DO NOT EDIT -- end ceph-rest-api"
    - content: '[client.restapi]'
    - append_if_not_found: True
    - backup: '.bak'
    - show_changes: True
    - require:
      - cmd: create-ceph-restapi-keyring
    - watch_in:
      - service: ceph
      - service: inkscope-cephprobe
      - service: sysprobe

ceph-rest-api-clusterconf-accumulated:
  file.accumulated:
    - filename: /etc/ceph/ceph.conf
    - name: ceph-rest-api-clusterconf-accumulator
    - text:
      - "log_file = /dev/null"
      - "keyring = {{ keyring_file }}"
    - require_in:
      - file: ceph-rest-api-clusterconf

## apache stuff

apache2:
  pkg.installed:
    - require_in:
      - service: apache2
  service:
    - running

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
    - source: salt://templates/inkscope/monitor/inkscope_vhost.conf
    - template: jinja
    - context:
        port: {{ port }}
        servername: localhost
        serveralias:
          - {{ grains.host }}
          - {{ grains.fqdn }}

apache-enable-inkscope-vhost:
  cmd.wait:
    - name: a2ensite {{ vhost }}
    - watch:
      - file: apache-inkscope-vhost
    - watch_in:
      - service: apache2

restart-apache:
  cmd.wait:
    - name: service apache2 restart
    - order: last
    - watch:
      - service: apache2

## inkscope

inkscope-cephprobe:
  service.running:
    - name: cephprobe
    - enable: True
    - watch:
      - file: inkscope-opt-conf

## cephprobe cannot use the same file as the other inkscope packages because it
## calls the full path of the api, which duplicates the api subfolder in the
## HTTP requests
##
## this might be fixed in the inkscope-cephprobe package later, so keep this
## in check

patch-cephprobe-configfile-path:
  cmd.run:
    - name: sed -i "s|^configfile = .*|configfile = '{{ cephprobe_cfg }}'|g" {{
      cephprobe_bin }}
    - unless: egrep -q "^configfile = '{{ cephprobe_cfg }}'" {{ cephprobe_bin }}
    - watch_in:
      - service: inkscope-cephprobe

cephprobe-opt-conf:
  file.managed:
    - name: /opt/inkscope/etc/cephprobe.conf
    - source: salt://templates/inkscope/base/inkscope.conf
    - template: jinja
    - context:
      ceph_cluster: ceph
      ceph_rest_api_host: {{ pillar.inkscope.mon.api.host }}
      ceph_rest_api_port: {{ pillar.inkscope.mon.api.port }}
      ceph_rest_api_subfolder: ceph-rest-api
      mongodb_host: {{ pillar.inkscope.base.mongo.host }}
      mongodb_user: {{ pillar.inkscope.base.mongo.user }}
      mongodb_passwd: {{ pillar.inkscope.base.mongo.pass }}
    - watch_in:
      - service: inkscope-cephprobe

cephprobe-conf-read-rights:
  cmd.run:
    - name: setfacl -m u:www-data:r /opt/inkscope/etc/cephprobe.conf
    - unless: getfacl /opt/inkscope/etc/cephprobe.conf | grep "user:www-data:r"
