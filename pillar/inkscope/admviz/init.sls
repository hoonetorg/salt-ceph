inkscope:
  pip_pkgs:
    admviz:
      - simplejson
      - flask
  pkgs:
    admviz:
      - inkscope-admviz
  admviz:
    vhost:
      name: inkscope
      port: 8080
    api:
      host: ceph-mon-1
      port: 8080
