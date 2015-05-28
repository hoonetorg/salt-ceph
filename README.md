This is a Salt state tree for a basic Ceph cluster.

<b>Master Configuration</b>

Make sure the contents of `config/master.d/` are present in the
`/etc/salt/master.d` directory on the master. It contains some pillar
extensions we use.

<b>Minion Configuration</b>

To deploy a new minion from debian-arkena, use the `minion-install.sh` script
contained in the `config` directory. The minion id is defined by the
`hostname -f` command, so you should either assign an appropriate hostname to
your new minion, or modify the minion_id after running the script.

<b>Call order</b>

You should first create your cluster on the monitor node and then deploy the
dashboard on the admin node, although it won't hurt to call highstate on the
admin node first, it just won't have access to your cluster as long as you
don't call it a second time to retrieve the keyring needed to have the right
permissions on your cluster to monitor it.

<b>Notes</b>

You should be calling highstate on only one OSD at a time, or Ceph will only
add the first one to call the admin node to the cluster (it doesn't support
concurrent calls).

There is a bug is salt as of 22/05/2015 which requires the adm node highstate
to be called twice to create the user and db in mongodb (see
https://github.com/saltstack/salt/issues/8933)
