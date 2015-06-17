mine_functions:
  ipaddrs:
    - mine_function: grains.get
    - ip4_interfaces
  fqdn:
    - mine_function: cmd.run
    - hostname -s
  bootstrap.osd: []
  bootstrap.mds: []
  bootstrap.api: []
  bootstrap.admin: []
  bootstrap.ids: []
