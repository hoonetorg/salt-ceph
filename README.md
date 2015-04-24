This is a Salt state tree for a basic Ceph cluster.

It includes a small DNS resolver (not recursor) to hold all the nodes in the
cluster. Every time a minion connects to the Salt master, it is automatically
added to the hosts file in the DNS machine (the DNS server expands the hosts
known by its host).

To deploy a new minion from debian-arkena, use the `minion-install.sh` script
contained in the `config` directory. The minion id is defined by the
`hostname -s` command, so you should either assign an appropriate hostname to
your new minion, or modify the minion_id after running the script.
