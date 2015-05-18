inkscope:
  pip_pkgs:
    adm:
      - simplejson
      - flask
  pkgs:
    adm:
      - inkscope-admviz
  adm:
    vhost:
      name: inkscope
    api:
      host: ceph-mon-1
      port: 8080
