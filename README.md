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

You should first create your cluster on the initial monitor node and then
deploy the dashboard on the admin node, although it won't hurt to call
highstate on the admin node first, it just won't have access to your cluster as
long as you don't call it a second time to retrieve the keyring needed to have
the right permissions on your cluster to monitor it.

After the first monitor is created, you can add any node in any order you want.

<b>Adding and removing OSDs</b>

OSD disks should have a valid GPT for `sgdisk` to work with (an empty one,
otherwise if any partition is present the OSD won't be created to preserve
disk data). You can create one with `sgdisk /path/to/disk -o`. I chose not to
automate this part because I think it is too critical to leave to a machine.

You can remove one or multiple OSDs with the `services.ceph.osd.remove_osd` sls

Example:
<pre>salt 'ceph-osd-1.mycluster' state.sls pillar='{
ceph_run: { osd: { remove: { ids: [2, 3], disks: ['/dev/sdc'] }}}}'</pre>
will remove the OSD corresponding to `/dev/sdc`, `osd.2` and `osd.3` on
`ceph-osd-1.mycluster`. If `osd.2` or `osd.3` correspond to `/dev/sdc`, the
second attempt to remove it will obviously fail.

Removing an OSD this way will not modify the associated disk. In fact, it will
not touch it besides unmounting its OSD data partition.

Also, it is imperative to call `mine.update` on the monitors to update the data
every time you add/remove a node to/from your cluster. Otherwise, next time you
add a new one, it might try to use a node id that is already in use and it will
fail.

<b>Notes</b>

There is a bug is salt as of 22/05/2015 which requires the adm node highstate
to be called twice to create the user and db in mongodb (see
https://github.com/saltstack/salt/issues/8933)
