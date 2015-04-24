#!/bin/sh
SALTMASTER=10.8.8.137
apt-get install -t wheezy python-requests salt-minion
echo -n `hostname -s` > /etc/salt/minion_id
echo "$SALTMASTER	salt" >> /etc/hosts
service salt-minion restart
#salt-call state.highstate
