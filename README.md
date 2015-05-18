This is a Salt state tree for a basic Ceph cluster.

<b>Master Configuration</b>

Make sure the contents of `config/master.d/` are present in the
`/etc/salt/master.d` directory on the master. It contains the list of reactor
states that automatically add nodes to the cluster, as well as pillar
extensions we use.

<b>Minion Configuration</b>

To deploy a new minion from debian-arkena, use the `minion-install.sh` script
contained in the `config` directory. The minion id is defined by the
`hostname -f` command, so you should either assign an appropriate hostname to
your new minion, or modify the minion_id after running the script.

<b>Call order</b>

On a first-time deployment, make sure you call highstate on nodes in this order:

- all initial monitors
- admin node
- inkscope monitor
- anything else

the reason for this is that the admin node creates the cluster on highstate,
so the initial monitors need to have ceph packages installed, as well as the
passwordless sudo access over ssh, before the admin calls them. once the
cluster is created, call highstate on the inkscope monitor again to configure
the REST api inkscope needs. then call highstate over any OSD or MDS node to
automatically include it in the cluster (adding a monitor dynamically is not
supported yet in this state tree).

<b>Notes</b>

You should be calling highstate on only one OSD at a time, or Ceph will only
add the first one to call the admin node to the cluster (it doesn't support
concurrent calls).