ceph:
  base:
    pkgs:
      adm:
        - ceph-deploy
    ferm:
      open_ports:
        mongodb: 27017
        cephrestapi: 8080
  adm:
    clusterdir: ceph-infralab
