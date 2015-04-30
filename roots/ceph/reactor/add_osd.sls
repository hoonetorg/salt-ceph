add osd with adm node:
  local.state.sls:
    - tgt: 'ceph-adm-1'
    - arg:
      - ceph.adm.reactor.add_osd
    - kwarg:
        pillar:
          osd:
            name: {{ data.id }}
            pathlist: {{ data.data.pathlist }}
