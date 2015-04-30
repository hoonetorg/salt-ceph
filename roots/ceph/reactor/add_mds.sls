add mds with adm node:
  local.state.sls:
    - tgt: 'ceph-adm-1'
    - arg:
      - ceph.adm.reactor.add_mds
    - kwarg:
        pillar:
          mds:
            name: {{ data['id'] }}
