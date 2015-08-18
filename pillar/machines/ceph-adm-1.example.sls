ceph:
  node:
    type:
      - adm # admin node (inkscope supervisor)
      # - node # basic ceph node (required by mds|mon|osd)
      # - mds # metadata server (not implemented)
      # - mon # monitor
      # - mon.master # master monitor
      # the master monitor is the one that creates a cluster if it doesn't find
      # a local valid configuration. the other ones will try to retrieve
      # the information and fail if they can't find it
      # the master monitor also requires the mon type
      # - mon.slave # slave monitor, will join an existing cluster
      # or fail if it can't find one
      # - osd # object storage daemon
inkscope:
  node:
    type:
      - adm # admin node (inkscope supervisor)
      # - this node hosts the web interface and the collector daemon (cephprobe)
      # - node # basic inkscope node, will send system information via sysprobe
      # should be enabled on all nodes except the supervisor
