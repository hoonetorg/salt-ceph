base:
  ferm:
    ports:
      # these entries are looped upon
      # label_in_comments: port_range
      # example:
      # salt-master: "4505:4506"
      ceph-osd: "6800:7300"
