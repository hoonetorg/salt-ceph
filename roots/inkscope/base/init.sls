apt-transport-https:
  pkg.installed:
    - require_in:
      - pkgrepo: inkscope-repo

inkscope-repo:
  pkgrepo.managed:
    - name: deb https://raw.githubusercontent.com/inkscope/inkscope-packaging/master/DEBS ./
    - file: /etc/apt/sources.list.d/inkscope.list
    - require_in:
      - pkg: inkscope-pkgs

inkscope-pkgs:
  pkg.installed:
    - skip_verify: True
    - pkgs:
      {% for _, pkglist in pillar.inkscope.pkgs.iteritems() %}
        {% for pkg in pkglist %}
      - {{ pkg }}
        {% endfor %}
      {% endfor %}

## python stuff

python-pkgs:
  pkg.installed:
    - pkgs:
      - python-dev
      - python-pip
      - python-requests
      - python-pymongo

{% for _, plist in salt['pillar.get']('inkscope.pip_pkgs', {}).iteritems() %}
  {% for pkg in plist %}

pip-pkg-{{ pkg }}:
  pip.installed:
    - name: {{ pkg }}
    - require:
      - pkg: python-pkgs

  {% endfor %}
{% endfor %}

inkscope-opt-conf:
  file.managed:
    - name: /opt/inkscope/etc/inkscope.conf
    - source: salt://inkscope/base/templates/inkscope.conf
    - template: jinja
    - context:
      ceph_cluster: ceph
      ceph_rest_api_host: {{ pillar.inkscope.base.api.host }}
      ceph_rest_api_port: {{ pillar.inkscope.base.api.port }}
      ceph_rest_api_subfolder: ceph-rest-api
      mongodb_host: {{ pillar.inkscope.base.mongo.host }}
      mongodb_user: {{ pillar.inkscope.base.mongo.user }}
      mongodb_passwd: {{ pillar.inkscope.base.mongo.pass }}
