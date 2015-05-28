inkscope:
  pip_pkgs:
    adm:
      - simplejson
      - flask
  pkgs:
    adm:
      - inkscope-admviz
    cephrestapi:
      - inkscope-cephprobe
      - inkscope-cephrestapi
  adm:
    vhost:
      name: inkscope
    api:
      host: ceph-adm-1
      port: 8080
