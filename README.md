This is a Salt state tree for a basic Ceph cluster.

Master Configuration

Make sure the `config/master.d/reactor.conf` is present in the
`/etc/salt/master.d` directory on the master. It contains the list of reactor
states that automatically add nodes to the cluster, for instance.

Minion Configuration

To deploy a new minion from debian-arkena, use the `minion-install.sh` script
contained in the `config` directory. The minion id is defined by the
`hostname -f` command, so you should either assign an appropriate hostname to
your new minion, or modify the minion_id after running the script.

Notes

You should be calling highstate on only one OSD at a time, or Ceph will only
add the first one to call the admin node to the cluster.
