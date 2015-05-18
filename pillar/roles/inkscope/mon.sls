inkscope:
  pkgs:
    cephrestapi:
      - inkscope-cephprobe
      - inkscope-cephrestapi
      - inkscope-admviz
  mon:
    api:
      vhost: inkscope
      host: ceph-mon-1
      port: 8080
