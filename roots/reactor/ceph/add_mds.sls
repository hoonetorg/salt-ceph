add-mds-from-adm-node:
  local.state.sls:
    - tgt: 'ceph-adm-1'
    - arg:
      - services.ceph.adm.reactor.create_mds
    - kwarg:
        pillar:
          reactor:
            mds:
              name: {{ data['id'] }}
