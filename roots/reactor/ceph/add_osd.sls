add-osd-from-adm-node:
  local.state.sls:
    - tgt: 'ceph-adm-1'
    - arg:
      - services.ceph.adm.reactor.create_osd
    - kwarg:
        pillar:
          reactor:
            osd:
              name: {{ data.id }}
              disklist: {{ data.data.disklist }}
