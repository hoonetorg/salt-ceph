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
{% set api_url = "http://" ~ pillar.inkscope.admviz.api.host + ":" ~
  pillar.inkscope.admviz.api.port + "/ceph-rest-api/api/v0.1" %}
{% set vhost = pillar.inkscope.admviz.vhost.name %}
{% set port = pillar.inkscope.admviz.vhost.port %}

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
    - source: salt://inkscope/admviz/templates/inkscope_vhost.conf
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
